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
// Important!!
// Make this path the correct path to the directory containing these files:
~mainPath = "/Users/charles/Music/SC/MusicForBusInterchanges/";
//

//
// Initialisation
//
Server.default = s = Server.local;
s.recSampleFormat = "int16";
s.recChannels = 2;

// Initialise busclock - tempo is 2 (bus) minutes per second
//~busClock = TempoClock.new(2, 0, Main.elapsedTime.ceil,4096); // Initialise and the bus clock

// Initialise busclock - tempo is 1 (bus) minute per second
~busClock = TempoClock.new(0.3, 0, Main.elapsedTime.ceil,4096); // Initialise and the bus clock


s.waitForBoot({
	// Create an array and fill it with buffers of bus sound
	var soundPathBase = ~mainPath ++ "soundfiles/"; 
	var soundPrefix = "bus";
	var pathSC = ~mainPath, fp, textArray, newLineChar;
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
	
	"Loading the bus soundsÉ".postln;
	"Waiting a few seconds.".postln;
	10.wait;
	
	//
	// Functions
	//
	// Play a bus sound from platform in direction
//	~playBus = {arg platform, direction;
//		var soundArray = [~busArray,~nightBusArray,~nightLoopArray,~nightPeopleArray].wchoose([0.5,0.3,0.2,0.1]);
//		var busNum = soundArray.size.rand; //array location of bus sound
//		var busLoop = 0;
//		//Play a bus sound
//		SynthDef("bus" ++ busNum ++ "_Player", {
//			arg out = 0;
//			var source = PlayBuf.ar(
//				soundArray[busNum].numChannels, 
//				soundArray[busNum].bufnum, 
//				doneAction: 2,
//				loop: busLoop
//			);
//			var pan;
//			if ((platform % 2 == 0), {pan = 0.7}, {pan = -0.7});
//			Out.ar(
//				out, 
//				Balance2.ar(source[0],source[1],0,0.3)
//			)
//			
//		}).play(s);
//		//Report
//		//("Played Bus" ++ busNum).postln;
//		//("Platform:" + platform).postln;
//		//("Direction:" + direction).postln;
//	};
	
	// New Playbus synthdef with envelopes
	~playBus = {arg platform, direction;
		var soundArray = [~busArray,~nightBusArray,~nightLoopArray,~nightPeopleArray].wchoose([0.5,0.3,0.2,0.1]);
		var busNum = soundArray.size.rand; //array location of bus sound
		var busLoop = 0;
		//Play a bus sound
		SynthDef("bus" ++ busNum ++ "_Player", {
			arg out = 0;
			var env = EnvGen.kr(Env.asr(1,1,1),doneAction:2);
			var source = PlayBuf.ar(
				soundArray[busNum].numChannels, 
				soundArray[busNum].bufnum, 
				doneAction: 2,
				loop: busLoop
			) * env;
			var pan;
			if ((platform % 2 == 0), {pan = 0.7}, {pan = -0.7});
			Out.ar(
				out, 
				Balance2.ar(source[0],source[1],0,0.3)
			)
			
		}).play(s);
		//Report
		//("Played Bus" ++ busNum).postln;
		//("Platform:" + platform).postln;
		//("Direction:" + direction).postln;
	};	
	
	
	// Schedule a bus
	~scheduleBus = {arg time, platform, direction, bus;
		var minutes;
		//Report data
		//("Time:" + time).postln;
		//("Platform:" + platform).postln;
		//("Direction:" + direction).postln;
	
		//Convert time into raw minutes
		//minutes = (time[0] * 60) + time[1];
		//("Raw minutes:" + minutes).postln;
		
		//Convert time into raw minutes, starting five hours earlier
		minutes = ((time[0] - 6) * 60) + time[1] + 20;
		
		//Schedule a bus sound from platform
		~busClock.sched(
			minutes,
			{
				~playBus.value(platform, direction);
				("Played the" + bus + "at" + time ++ ".").postln;
			}
		);
	};
	
	//
	// Processing the Bus Schedule	
	//
	// Process the 300 Buses.
	//
	~scheduleFilePath = pathSC ++ "3xxSchedule.csv";
	fp = File(~scheduleFilePath, "r"); // Load the schedule
	textArray = fp.readAllString; //read the file into a string
	newLineChar = textArray[20]; // Find the character for newline
	textArray = textArray.split(newLineChar); //split by newlines (not sure what character code is here...)
	// Process each bus
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
	//	// Parse direction, 0 is south and 1 is north.
		if (textArray[i][2].contains("south"), {
			textArray[i][2] = 0; //south
		},{
			textArray[i][2] = 1; //north
		});
	});
	// end parsing
	("Bus Schedule Parsed.").postln;
	
	//
	// Process the not 300 buses
	//
	~scheduleFilePath = pathSC ++ "not3xxSchedule.csv";
	fp = File(~scheduleFilePath, "r"); // Load the schedule
	textArray = fp.readAllString; //read the file into a string
	textArray = textArray.split(newLineChar); //split by newlines (not sure what character code is here...)
	// Process each bus
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
	//	// Parse direction, 0 is south and 1 is north.
		if (textArray[i][2].contains("south"), {
			textArray[i][2] = 0; //south
		},{
			textArray[i][2] = 1; //north
		});
	});
	// end parsing
	("Bus Schedule Parsed.").postln;
	
	// Schedule the sounds!
	for(0, (textArray.size - 1), {arg i;
		// Post the Schedule
	//	("Scheduling a" + textArray[i][0] + "at" 
	//		+ textArray[i][1] + "at platform" 
	//		+ textArray[i][3] ++ ".").postln;
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
)
