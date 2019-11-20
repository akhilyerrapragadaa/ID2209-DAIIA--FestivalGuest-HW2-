
model BaseAssignment

/*
 Silent auction
 The person who wins. Sell for a higher price?
 * 
 * This code is based on the code below with modifications:
 * https://github.com/gama-platform/gama/wiki/FIPA-Skill-FIPA-CFP-(2)
 */

global {
	
	int globalDelayTime <- 50; //time before auctioner restarts
	int nbOfParticipants <- 5; //people
	int circleDistance <- 8; 
	int distanceToAuction <- 100; //how far away I will consider to join an auction
	list<list> participantsDecidedToJoin <- [[],[],[],[],[],[]];
	list<list> participantsDecidedToJoin_hasarrived <- [[],[],[],[],[],[]];
	
	/* Auctioneer0  */	
	//participant inform_done_participant0;
	//list<participant> inform_result_participant0;
	//int numOfRefusers0 <-0;
	
	list<participant> inform_done_participant <- [nil,nil,nil,nil,nil];
	list<list> inform_result_participant <- [[],[],[],[],[],[]];
	list<int> numOfRefusers <- [0,0,0,0,0];
	
	
	
	
	init {
				
		create initiator number: 1// returns: ps
		{
		location <- {50,50,0};
		participantListIndex <- 0;
		ItemType <- 'Clothes';
		}
		create participant number: nbOfParticipants returns: ps;
				
		write 'Please step the simulation to observe the outcome in the console';
	}
}

species initiator skills: [fipa] {
	
	int startBid <- rnd(500,5000);
	int minBid <- rnd(10,(startBid/4));
	//int minBid <- startBid-100;
	bool foundWinner <- false;
	string ItemType;
	bool sent_info <- false;
	bool sent_first <- false;
	
	int delayStart;
	bool delayOK <- true;
	bool foundMinBid <- false;
	
	int participantListIndex;	
		
	reflex resetAttributes when: foundWinner 
	{
		startBid <- rnd(500,5000);
		sent_info <- false;
		sent_first <- false;
		minBid <- rnd(10,(startBid/4));
		foundWinner <- false;
		inform_result_participant[participantListIndex] <- [];
		inform_done_participant[participantListIndex] <- nil;
		delayOK <- false;
		delayStart <- time;	
		participantsDecidedToJoin[participantListIndex] <- [];
		participantsDecidedToJoin_hasarrived[participantListIndex] <- [];
		numOfRefusers[participantListIndex]<-0;
		
	}
	
		
	reflex countDelay when: !delayOK 
	{
		if((time-delayStart)>globalDelayTime)
		{
			delayOK<-true;
		}
			
	}
	
		
	reflex send_info_to_possible_participants when: !sent_first and !sent_info and delayOK {
		
		
		write '(Time ' + time + '): ' + name + ' sends a inform message to all participants';
		do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: [("Inform: Auction starts at: "+self.name),ItemType,self,participantListIndex] ];
		sent_info <- true;
		
	}
	
	reflex send_cfp_to_participants when: !sent_first and sent_info and length(participantsDecidedToJoin[participantListIndex])>0 and length(participantsDecidedToJoin[participantListIndex])=length(participantsDecidedToJoin_hasarrived[participantListIndex]) {
		
		sent_first <- true;
		
		if (startBid<minBid)
		{
		write '(Time ' + time + '): ' + name + ' Minimum bid: '+minBid+'END Auction ********************';
		do start_conversation with: [ to :: list(participantsDecidedToJoin[participantListIndex]), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: [("Inform: ENDS: "+self.name),"Ends",self,participantListIndex] ];
		foundWinner <- true;
		sent_info <- false;
		}
		else{
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		do start_conversation with: [ to :: list(participantsDecidedToJoin[participantListIndex]), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [ItemType,startBid] ];
	}
	}
	
	reflex receive_refuse_messages when: !empty(refuses) {
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		
		loop r over: refuses {
			write '\t' + name + ' receives a refuse message from ' + agent(r.sender).name + ' with content ' + r.contents ;
			numOfRefusers[participantListIndex]<-numOfRefusers[participantListIndex]+1;
		}
		
		//ALL REFUSES
		if(numOfRefusers[participantListIndex]=length(participantsDecidedToJoin[participantListIndex]))  
		{
			write "Go into next round and reduce price";
			startBid<-startBid-rnd(1,startBid/2);
			numOfRefusers[participantListIndex]<-0;
			if (startBid<minBid)
			{
			write '(Time ' + time + '): ' + name + ' Minimum bid: '+minBid+'END Auction ********************';
			do start_conversation with: [ to :: list(participantsDecidedToJoin[participantListIndex]), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: [("Inform: ENDS: "+self.name),"Ends",self,participantListIndex] ];
			foundWinner <- true;
			sent_info <- false;
			}
			else
			{
			do start_conversation with: [ to :: list(participantsDecidedToJoin[participantListIndex]), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [ItemType,startBid] ];	
			}
			
		}
		
		
	}
	
	reflex receive_propose_messages when: !empty(proposes) {
		write '(Time ' + time + '): ' + name + ' receives propose messages';
		
		loop p over: proposes {
		
			write '\t' + name + ' receives a propose message from ' + agent(p.sender).name + ' with content ' + p.contents ;
			
			if (foundWinner) { //If already found winner. Reject
			
				add p to: inform_result_participant;
				write '\t' + name + ' sends a reject_proposal message to ' + p.sender;
				do reject_proposal with: [ message :: p, contents :: ['Not interested in your proposal'] ];
							
			} else { //First winner
				inform_done_participant <- p;
				write '\t' + name + ' sends a accept_proposal message to ' + p.sender;
				do accept_proposal with: [ message :: p, contents :: ['I will go with your proposal'] ];
								
				//Signal auction ended
				remove p.sender from: list(participantsDecidedToJoin[participantListIndex]);
				do start_conversation with: [ to :: list(participantsDecidedToJoin[participantListIndex]), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: [("Inform: ENDS: "+self.name),"Ends",self,participantListIndex] ];
				foundWinner <- true;
				
			}
		}
	}
	
	reflex receive_failure_messages when: !empty(failures) {
		message f <- failures[0];
		write '\t' + name + ' receives a failure message from ' + agent(f.sender).name + ' with content ' + f.contents ;
	}
	
	reflex receive_inform_messages when: !empty(informs) {
		write '(Time ' + time + '): ' + name + ' receives inform messages';
		
		loop i over: informs {
			write '\t' + name + ' receives a inform message from ' + agent(i.sender).name + ' with content ' + i.contents ;
		}
	}
	aspect base {
		draw circle((circleDistance)#m) color: #lightblue depth:1;
		draw circle(1) color: #red depth:4;
	}
}

species participant skills: [fipa,moving] {
	
	//random value of half of the first initiatior.
	bool sat_bid_price <- false;
	int maxPrice <- 0;
	bool busy <- false;
	bool gotFirstProposal <- false;
	bool goingToAuction <- false;
	bool set_interestitem <- false;
	int firstProposal;
	string interestItem <- "Clothes";
	int participantListIndex;
	
	point initPoint <- {(rnd(0,100)),(rnd(0,100)),0};
	
	point targetPoint <- nil;
	
	
/* 	reflex setInterestitem when: !(set_interestitem) {
		do wander;
	}*/
	
	
	    
    reflex beIdle when: !(busy) {
		do wander;
		}
		
	reflex moveToTarget when: targetPoint != nil
	{
		do goto target:targetPoint;
	}
	
	reflex arrivedAtAuction when: goingToAuction{
			if(distance_to(self,targetPoint)<1){
			
			write self.name + "At Auction";
			self.targetPoint <- nil;
			add self to: participantsDecidedToJoin_hasarrived[participantListIndex];
			self.goingToAuction <- false;
			
			}
		}
		
	reflex goBackToInitPoint when: distance_to(self,initPoint)<1 and busy{
			if(targetPoint=initPoint){
			write self.name + "At InitPoint";
			self.targetPoint <- nil;
			self.busy <- false;
			
			}
		}
	
	
	
		
		
	
		reflex receive_startInfo_from_initiator when: !empty(informs) and !busy {
		message informFromInitiator <- informs[0];
		write '(Time ' + time + '): ' + name + ' receives a INFORM message from ' + agent(informFromInitiator.sender).name + ' with content ' + informFromInitiator.contents;
		
		agent auctioneer <- informFromInitiator.contents[2];
		string auctionItem <- informFromInitiator.contents[1];
		participantListIndex <- informFromInitiator.contents[3];

		
		if (distance_to(self,auctioneer)<=distanceToAuction and auctionItem=interestItem)
		{
			write name + ' decides to join auction at: ' + agent(informFromInitiator.sender).name+"loc:";
			add self to: participantsDecidedToJoin[participantListIndex];
			self.busy <- true;	
			self.targetPoint <- any_location_in(auctioneer);
			self.targetPoint <- {(targetPoint.x-rnd(1,circleDistance/2)),(targetPoint.y-rnd(circleDistance/2)),targetPoint.z};
			self.goingToAuction <- true;
		}
			
			
		}
		
		//receive end INFO
		reflex receive_otherInfo_from_initiator_wile_busy when: !empty(informs) and busy{

		message informFromInitiator <- informs[0];
		write '(Time ' + time + '): ' + name + ' receives a INFORM message from ' + agent(informFromInitiator.sender).name + ' with content ' + informFromInitiator.contents;
		
		agent auctioneer <- informFromInitiator.contents[2];
		string infoText <- informFromInitiator.contents[1];
		participantListIndex <- informFromInitiator.contents[3];

		
		if (infoText="Ends")
		{
			write name + ' Goes home: ';
			self.targetPoint <- self.initPoint;			
			self.goingToAuction <- false;
		}
			
			
		}
		
		
		
		reflex receive_cfp_from_initiator when: !empty(cfps) and busy {
		
		message proposalFromInitiator <- cfps[0];
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ' with content ' + proposalFromInitiator.contents;
		
		firstProposal <- proposalFromInitiator.contents[1];
		
		if(!sat_bid_price)
		{
		maxPrice <- (rnd(0,(firstProposal)/2));
		sat_bid_price <- true;
		}
		
		write '(Time ' + time + '): ' + name + ' i will accept' +self.maxPrice;
			
		//BIDDER					AUCTIONER - random
		//3200				5000, 4000, 3300 , 2200 returns random number	
		//accept self.maxPrice > firstProposal
		if (self.maxPrice >= firstProposal) {
			write '\t' + name + ' sends a propose message to ' + agent(proposalFromInitiator.sender).name;
			do propose with: [ message :: proposalFromInitiator, contents :: ['I will buy for that price'] ];
		}
		
		else  {
			write '\t' + name + ' sends a refuse message to ' + agent(proposalFromInitiator.sender).name;
			do refuse with: [ message :: proposalFromInitiator, contents :: ['I will not buy'] ];
		}
	}
	
	reflex receive_reject_proposals when: !empty(reject_proposals) {
		message r <- reject_proposals[0];
		write '(Time ' + time + '): ' + name + ' receives a reject_proposal message from ' + agent(r.sender).name + ' with content ' + r.contents;
	}
	
	reflex receive_accept_proposals when: !empty(accept_proposals) {
		message a <- accept_proposals[0];
		write '(Time ' + time + '): ' + name + 'receives a accept_proposal message from ' + agent(a.sender).name + ' with content ' + a.contents;
		self.targetPoint <- self.initPoint;			
				
		//Winning
		if (self = inform_done_participant) {
			write '\t' + name + ' sends an inform_done message to ' + agent(a.sender).name;
			do inform with: [ message :: a, contents :: ['Inform done'] ];
			self.targetPoint <- self.initPoint;			
		}
		
		//Loosing
		list results <- inform_result_participant;
		
		bool containResult <- results contains_key self; // var1 equals true 
		
		if (containResult) {
			write '\t' + name + ' sends an inform_result message to ' + agent(a.sender).name;
			do inform with: [ message :: a, contents :: ['Inform result'] ];
			self.targetPoint <- self.initPoint;			
		}
	}
	
	aspect base {
		draw circle(1) color: #blue depth:1;
	}
	
}

experiment test type: gui {
	//parameter "Total People in Aution" var: number_of_people;
	//parameter "Initiators" var: nbOfinitiators;
	output {
		display my_display type:opengl {
			species initiator aspect:base;
			species participant aspect:base;	
			
			
			}
	}
}
