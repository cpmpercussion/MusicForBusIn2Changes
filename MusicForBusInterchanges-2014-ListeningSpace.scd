// In2Change - Sonic bus station experiment
// Author: Charles Martin
// February/March 2009

// I composed this work for an exhibition of art related to the closure of a bus interchange in
// the town centre of Belconnen, Canberra. The program reads in a timetable of the buses and plays
// field recordings of buses at the interchange whenever one departs in the timetable. The piece
// runs on a scale of 1 minute = 1 second, but I intended that it could be drawn out to a full day
// and played in the, now demolished, bus interchange.

// Run the chunk of code inside this parenthesis, the server will boot and the piece will
// start in a few seconds.
(
~mainPath = thisProcess.nowExecutingPath.dirname ++ "/";

~outChannels = 4;
~recording = false;
~shortsounds = true;

o = Server.local.options;
o.numOutputBusChannels = ~outChannels;
Server.default = s = Server.local;
s.recHeaderFormat = "aiff";
s.recSampleFormat = "int16";
s.recChannels = ~outChannels;

// Initialise busclock - tempo is 2 (bus) minutes per second
//~busClock = TempoClock.new(2, 0, Main.elapsedTime.ceil,4096); // Initialise and the bus clock

// Initialise busclock - tempo is 1 (bus) minute per second
//~speed = 0.3; // minutes per second
~speed = 2.0;
//~speed = 1.2;

~busClock = TempoClock.new(~speed, 0, Main.elapsedTime.ceil,4096); // Initialise and the bus clock


s.waitForBoot({
	// Create an array and fill it with buffers of bus sound
	var soundPathBase = ~mainPath ++ "soundfiles/";
	var soundPrefix = "bus";
	var fp, textArray, newLineChar;

	if (~recording, {
		s.prepareForRecord;
	});


	~busArray = Array.fill(25,{
		arg i;
		var path;
		var filenum = i + 1;
		// Format the 'path' string correctly.
		if (filenum < 10, {
			path = soundPathBase ++ soundPrefix ++ 0 ++ filenum ++ ".aif";
		},{
			path = soundPathBase ++ soundPrefix ++ filenum ++ ".aif";
		});
		//path.postln;
		Buffer.read(s, path, action: { arg buffer; ("Buffer loaded:" + buffer.numFrames).postln;});
	});

	~nightBusArray = Array.fill(14,{
		arg i;
		var path;
		var filenum = i + 1;
		// Format the 'path' string correctly.
		if (filenum < 10, {
			path = soundPathBase ++ "nightbus" ++ 0 ++ filenum ++ ".aif";
		},{
			path = soundPathBase ++ "nightbus" ++ filenum ++ ".aif";
		});
		//path.postln;
		Buffer.read(s, path, action: { arg buffer; ("Buffer loaded:" + buffer.numFrames).postln;});
	});

	~nightLoopArray = Array.fill(8,{
		arg i;
		var path;
		var filenum = i + 1;
		// Format the 'path' string correctly.
		if (filenum < 10, {
			path = soundPathBase ++ "nightloop" ++ 0 ++ filenum ++ ".aif";
		},{
			path = soundPathBase ++ "nightloop" ++ filenum ++ ".aif";
		});
		//path.postln;
		Buffer.read(s, path, action: { arg buffer; ("Buffer loaded:" + buffer.numFrames).postln;});
	});

	~nightPeopleArray = Array.fill(5,{
		arg i;
		var path;
		var filenum = i + 1;
		// Format the 'path' string correctly.
		if (filenum < 10, {
			path = soundPathBase ++ "nightpeople" ++ 0 ++ filenum ++ ".aif";
		},{
			path = soundPathBase ++ "nightpeople" ++ filenum ++ ".aif";
		});
		//path.postln;
		Buffer.read(s, path, action: { arg buffer; ("Buffer loaded:" + buffer.numFrames).postln;});
	});

	"Loading the bus sounds.".postln;
	"Waiting a few seconds.".postln;
	10.wait;

	if (~recording, {
		s.record;
	});

	//
	// Functions
	//
	// Return a soundArray based on the hour of the bus leaving
	~getSoundArray = {arg hour;
		var soundArray = ~busArray;
		// Phases
		// 0 early 0 - 8
		// 1 morning 8 - 12
		// 2 afternoon 13 - 17
		// 3 evening 18 - 24
		if (hour < 8, {// early
			soundArray = [~nightBusArray,~nightLoopArray].wchoose([0.7,0.3])
		},{
			if (hour < 13, {// morning
					soundArray = ~busArray;
					},{
						if (hour < 18, {//afternoon
							soundArray = [~busArray,~nightBusArray].wchoose([0.7,0.3]);
							},{// evening
								soundArray = [~nightBusArray,~nightLoopArray,~nightPeopleArray].wchoose([0.5,0.2,0.3]);
		})})});
		soundArray;
	};


	// Play a bus sound from platform in direction
	// New Playbus synthdef with envelopes
	~playBus = {arg platform, direction, hour;
		var soundArray = ~getSoundArray.value(hour);
		var busNum = soundArray.size.rand; //array location of bus sound
		var busLoop = 1;
		var length = soundArray[busNum].numFrames / soundArray[busNum].sampleRate;
		if (~shortsounds, {length = 1.5 + (20.rand/10)});
		//Play a bus sound
		SynthDef("bus" ++ busNum ++ "_Player", {
			arg out = 0;
			var env = EnvGen.kr(
				Env.linen(length*0.5,length*0.1,length*0.5),
				levelScale:0.15 + (0.01*40.rand),
				doneAction:2);

			var source = PlayBuf.ar(
				soundArray[busNum].numChannels,
				soundArray[busNum].bufnum,
				rate: 0.9 + (20.rand/100),
				startPos:soundArray[busNum].numFrames.rand,
				loop: busLoop
			) * env;

			var az = -1.125 + (platform * 0.125);
			var shift = 0.05;
			var bFormatSource = PanB2.ar(source[0],az,0.3) + PanB2.ar(source[1],az+shift,0.3);
			var rotateSpeed = 0.005 * 5.rand;
			var rotatedSource = Rotate2.ar(bFormatSource[1],bFormatSource[2],direction * LFSaw.kr(rotateSpeed));
			Out.ar(
				out,
				DecodeB2.ar(~outChannels,bFormatSource[0],rotatedSource[0],rotatedSource[1]);
			)
		}).play(s);
	};

	// Schedule a bus
	~scheduleBus = {arg time, platform, direction, bus;
		var minutes;
		//minutes = (time[0] * 60) + time[1];
		minutes = ((time[0] - 6) * 60) + time[1] + 20; //Convert time into raw minutes, starting five hours earlier
		("Scheduled Time: " + minutes).postln;
		~busClock.sched( //Schedule a bus sound from platform
			minutes,
			{
				~playBus.value(platform, direction, time[0]);
				("Played the" + bus + "at" + time ++ ".").postln;
			}
		);
	};


	// Process Bus Schedule All Sounds Version.
	//var fp, textArray, newLineChar;
	~scheduleFilePath = ~mainPath ++ "totalSchedule.csv";
	fp = File(~scheduleFilePath, "r"); // Load the schedule
	textArray = fp.readAllString; //read the file into a string
	textArray = textArray.split($\n);

	for(0, (textArray.size - 1), {arg i;
		textArray[i] = textArray[i].split($,);
		// Parse time
		textArray[i][1] = textArray[i][1].split($:);
		textArray[i][1][0] = textArray[i][1][0].asInteger;
		if( textArray[i][1][1].contains("AM"), {
			//AM then
			textArray[i][1][1] = textArray[i][1][1].asInteger;
			// Change 12AM to 24
			if (textArray[i][1][0] == 12, { textArray[i][1][0] = 24;},{});
			if (textArray[i][1][0] == 1, { textArray[i][1][0] = 25;},{});
			if (textArray[i][1][0] == 2, { textArray[i][1][0] = 26;},{});
		},{
			//AM else
			if( textArray[i][1][1].contains("PM"), {
				// PM then
				textArray[i][1][1] = textArray[i][1][1].asInteger;
				// Change xPM (not 12) to x+12
				if (textArray[i][1][0] != 12, {
					textArray[i][1][0] = textArray[i][1][0] + 12;
				},{});
			},{
				// No AM or PM then do nothing.
			})
		});
	//	// Parse number and platform.
		textArray[i][0] = textArray[i][0].asInteger;
		textArray[i][3] = textArray[i][3].asInteger;
	//	// Parse direction, -1 is south and 1 is north.
		if (textArray[i][2].contains("south"), {
			textArray[i][2] = -1; //south
		},{
			textArray[i][2] = 1; //north
		});
	});
	// end parsing
	("Bus Schedule Parsed.").postln;

	// Schedule the sounds!
	for(0, (textArray.size - 1), {arg i;
		// Post the Schedule
		/*("Scheduling a" + textArray[i][0] + "at"
			+ textArray[i][1] + "at platform"
			+ textArray[i][3] ++ ".").postln;*/
		~scheduleBus.value(
			textArray[i][1],
			textArray[i][3],
			textArray[i][2],
			textArray[i][0]
		);
	});
	("Scheduled" + textArray.size + "buses from" + ~scheduleFilePath + ".").postln; //Post the number of buses scheduled.
// Finishing wait for boot line
});

)


(
// Stop the piece
~busClock.clear;
s.stopRecording;
)
