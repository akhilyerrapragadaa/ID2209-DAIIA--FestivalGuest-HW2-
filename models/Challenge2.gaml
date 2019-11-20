
model cfp_cfp_2

/*
 Silent auction
 The person who wins. Sell for a higher price?
 */

global {
	int nbOfParticipants <- 5;
	//int nbOfinitiators <- 1;
	participant refuser;
	list<participant> proposers;
	participant reject_proposal_participant;
	list<participant> accept_proposal_participants ;
	participant failure_participant;
	participant inform_done_participant;
	list<participant> inform_result_participant;
	int numOfRefusers <-0;
	int circleDistance <- 8;
	int globalDelayTime <- 100; //time before auctioner restarts
	
	/* About the World */
	int number_of_people <- 10;
	int nbOfinitiators <- 1;
	
	
	list<list> participantsDecidedToJoin <- [[],[],[],[],[],[]];
	list<list> participantsDecidedToJoin_hasarrived <- [[],[],[],[],[],[]];
	
	
	int distanceToAuction <- 100;
	
	init {
				
		create initiator number: nbOfinitiators// returns: ps
		{
		location <- {50,50,0};
		}
		create participant number: nbOfParticipants returns: ps;
		
		inform_result_participant <- [];
		inform_done_participant <- nil;
		
		write 'Please step the simulation to observe the outcome in the console';
	}
}

species initiator skills: [fipa] {
	
	int startBid <- rnd(50000,100000,50000);
	//int minBid <- rnd(10,(startBid/4));
	//bool foundWinner <- false;
	string ItemType <- 'MS Dhoni';
	bool playersold <- false;
	bool sent_info <- false;
	bool sent_first <- false;
	//int sort <-0;
	int delayStart;
	bool delayOK <- true;
	bool clutch <- false;
	
	int participantListIndex <- 0;	
	
		
	reflex resetAttributes when: playersold 
	{
		startBid <- rnd(50000,150000, 50000);
		//minBid <- rnd(10,(startBid/4));
		sent_info <- false;
		sent_first <- false;
		playersold <- false;
		inform_result_participant <- [];
		inform_done_participant <- nil;
		delayOK <- false;
		delayStart <- time;	
		participantsDecidedToJoin[participantListIndex] <- [];
		participantsDecidedToJoin_hasarrived[participantListIndex] <- [];
		numOfRefusers<-0;
		clutch <- false;
		//sort <-0;
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
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		do start_conversation with: [ to :: list(participantsDecidedToJoin[participantListIndex]), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [ItemType,startBid] ];
	}
	
	
	
	reflex receive_refuse_messages when: !empty(refuses)  {
		//int x <-0;
		int dummy <-0;
		list<list> removedParticipants <- [[],[],[],[],[],[]];
		//removedParticipants <- participantsDecidedToJoin ;
		string cont<-"";
		loop r over: refuses {
		//do start_conversation with: [ to :: list(participantsDecidedToJoin[participantListIndex]), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: [("Inform: ENDS: "+self.name),"Ends",self,participantListIndex] ];
		
		//remove r.sender from: list(removedParticipants[participantListIndex]);
		remove r.sender from: list(participantsDecidedToJoin[participantListIndex]);
		write '\t' + name + ' receives a refuse message from ' + agent(r.sender).name + ' with content ' + r.contents[0]+r.contents[1];
	   numOfRefusers<- r.contents[1];
	   
	   if(numOfRefusers > dummy){
				dummy <- numOfRefusers;  
				cont <- agent(r.sender).name;
			}
	}
    if(length(participantsDecidedToJoin[participantListIndex])=1){
		write '\t' +"Player sold to" + list(participantsDecidedToJoin[participantListIndex]);
		playersold <- true;
		do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: [("Inform: ENDS: "+self.name),"Ends",self,participantListIndex] ];
	}
 	if(length(participantsDecidedToJoin[participantListIndex])=0){
		write '\t' +"Player sold to"+" "+cont+" "+"for"+" "+dummy;
		playersold <- true;
		do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: [("Inform: ENDS: "+self.name),"Ends",self,participantListIndex] ];
	}
	//do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: [("Inform: ENDS: "+self.name),"Ends",self,participantListIndex] ];
	
	}
	
	
	
	reflex receive_propose_messages when: !empty(proposes) {
		
		if(!playersold){
		write '(Time ' + time + '): ' + name + ' receives propose messages';
	 	int v <-0;
		int sort <-0;
		int increment <-0;
		loop p over: proposes {
	
	
		write '\t' + name + ' receives a propose message from ' + agent(p.sender).name + ' with content ' + p.contents[0] + " "+ p.contents[1];
		   
		v <- p.contents[1];
			increment<-increment +1;
			if(v > sort){
				sort <- v;
				
			}
	
		}
		
		
		
		if(increment!=1){
			write "Bidding restarts at"+" "+ sort;
		    do start_conversation with: [ to :: list(participantsDecidedToJoin[participantListIndex]), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [ItemType,sort] ];
		}
		
		//}
		
	    
	
	/* 	if(length(participantsDecidedToJoin[participantListIndex])=2){
			loop p over: proposes {
				x<-p.contents[1];
				if(x > dummy){
				dummy <- x;
			    increment<-increment +1;
			}
			}
			if(dummy=1){
				do start_conversation with: [ to :: list(participantsDecidedToJoin[1]), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [ItemType,dummy] ];
			}
			else{
				do start_conversation with: [ to :: list(participantsDecidedToJoin[0]), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [ItemType,dummy] ];
			}
		}
		else{
			write "Bidding restarts at"+" "+ sort;
		do start_conversation with: [ to :: list(participantsDecidedToJoin[participantListIndex]), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [ItemType,sort] ];
		}*/
	}
	}
	 
	
	//reflex receive_propose_messages when: !empty(proposes) {}
	
	
	aspect base {
		draw circle((circleDistance)#m) color: #lightblue depth:1;
		draw circle(1) color: #red depth:4;
	}
}

species participant skills: [fipa,moving] {
	
	//random value of half of the first initiatior.
	bool sat_bid_price <- false;
	bool sat_bid_neg <- false;
	int maxPrice <- 0;
	int i_have <-0;
	bool busy <- false;
	bool gotFirstProposal <- false;
	bool goingToAuction <- false;
	int firstProposal;
	string interestItem <- "MS Dhoni";
	int participantListIndex;
	int mymax <-0;
	point initPoint <- {(rnd(0,100)),(rnd(0,100)),0};
	
	point targetPoint <- nil;
/* 	reflex resetAttributes when:!(busy) 
	{
		sat_bid_price <- false;
     sat_bid_neg <- false;
	 maxPrice <- 0;
	 i_have <-0;
	 busy <- false;
	 gotFirstProposal <- false;
	 goingToAuction <- false;
	int firstProposal;
	 interestItem <- "MS Dhoni";
	int participantListIndex;
	int mymax <-0;
		
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
			
		reflex receive_cfp_from_initiator when: !empty(cfps) and busy  {
		
		message proposalFromInitiator <- cfps[0];
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ' with content ' + proposalFromInitiator.contents;
		
		firstProposal <- proposalFromInitiator.contents[1];
		
		
		if(sat_bid_price){
		maxPrice <- rnd(firstProposal, i_have, 50000);
		}
		
		if(!sat_bid_price)
		{
		i_have <- rnd(100000,1000000, 50000);
		maxPrice <- rnd(100000, i_have, 50000);
	   
	  
   	sat_bid_price <- true;
		}
		ask participant{
			if(self.maxPrice = myself.maxPrice ){
				myself.maxPrice <- myself.maxPrice + rnd(myself.i_have,1000000 , 50000);               //rnd(self.maxPrice,self.i_have, 50000);
			   
			}
			}
				
		if (self.maxPrice >= firstProposal) {
			write '\t' + name + ' sends a propose message to ' + agent(proposalFromInitiator.sender).name +self.maxPrice;
			mymax<-self.maxPrice;
			do propose with: [ message :: proposalFromInitiator, contents :: ['I will buy '+self.interestItem+' for -',self.maxPrice, self.name] ];
		   
		}
		
	    if(self.maxPrice < firstProposal) {
			
			do refuse with: [ message :: proposalFromInitiator, contents :: ['The max I can go for this player is', self.mymax] ];
		}
	
	}
	
	aspect base {
		draw circle(1) color: #blue depth:1;
	}
	
}

experiment test type: gui {
	parameter "Total People in Aution" var: number_of_people;
	parameter "Initiators" var: nbOfinitiators;
	output {
		display my_display type:opengl {
			species initiator aspect:base;
			species participant aspect:base;	
			
			
			}
	}
}
