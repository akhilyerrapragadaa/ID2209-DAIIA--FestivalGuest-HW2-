
model cfp_cfp_3

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
	int globalDelayTime <- 80; //time before auctioner restarts
	//bool goingToAuction <- false;
	bool reachSecurity <- false;
	/* About the World */
	int number_of_people <- 10;
	int nbOfinitiators <- 1;
	int numberofSecurity <- 1;
	
	
	list<list> participantsDecidedToJoin <- [[],[],[],[],[],[]];
	list<list> participantsDecidedToJoin_hasarrived <- [[],[],[],[],[],[]];
	
	
	int distanceToAuction <- 100;
	
	init {
				
		create initiator number: nbOfinitiators// returns: ps
		{
		location <- {50,50,0};
		}
		create participant number: nbOfParticipants returns: ps;
		
		create security number:numberofSecurity
		{
			location <- {50,42,0};
		}
		inform_result_participant <- [];
		inform_done_participant <- nil;
		
		write 'Please step the simulation to observe the outcome in the console';
	}
}

species initiator skills: [fipa] {
	
	int startBid <- rnd(1000,5000,100);
	//int minBid <- rnd(10,(startBid/4));
	bool foundWinner <- false;
	string ItemType <- 'Clothes';
	bool itemsold <- false;
	bool sent_info <- false;
	bool sent_first <- false;
	int sort <-0;
	int delayStart;
	bool delayOK <- true;
    bool clutch <-false;
	bool flag<-false;
	int participantListIndex <- 0;	
	string first_best <-"";
	string second_best <-"";
	float dum <-0.0;
	float dumm <-0.0;
	
	reflex resetAttributes when: itemsold 
	{
		/*int startBid <- rnd(1000,5000,100);
		//minBid <- rnd(10,(startBid/4));
		sent_info <- false;
		sent_first <- false;
		foundWinner <- false;
		inform_result_participant <- [];
		inform_done_participant <- nil;
		delayOK <- false;
		delayStart <- time;	
		participantsDecidedToJoin[participantListIndex] <- [];
		participantsDecidedToJoin_hasarrived[participantListIndex] <- [];
		numOfRefusers<-0;*/
		startBid <- rnd(1000,5000,100);
	//int minBid <- rnd(10,(startBid/4));
	//goingToAuction <- false;
	foundWinner <- false;
	 ItemType <- 'Clothes';
	itemsold <- false;
	 sent_info <- false;
	 sent_first <- false;
	 sort <-0;
	delayStart <- time;
	 delayOK <- false;
     clutch <-false;
	 flag<-false;
	 participantListIndex <- 0;	
	 first_best <-"";
	 second_best <-"";
	 dum <-0.0;
	dumm <-0.0;
	participantsDecidedToJoin[participantListIndex] <- [];
		participantsDecidedToJoin_hasarrived[participantListIndex] <- [];
	}
		
 	reflex countDelay when: !delayOK 
	{
		if((time-delayStart)>globalDelayTime)
		{
			//write "TADAA";
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


	reflex receive_propose_messages when: !empty(proposes)  {
	float x <- 0.0;
	
	int i <-0;
	write '(Time ' + time + '): ' + name + ' receives propose messages';
	     
		loop p over: proposes {
			
			write '\t' + name + ' receives a propose message from ' + agent(p.sender).name + ' with content ' + p.contents[0] + " "+ p.contents[1];
			 x <- p.contents[1];
			
			if(x>dum){
			dumm <-dum+0.1;
		 	dum<-x;
		 	first_best <-agent(p.sender).name;
		 }
			 else if(x>dumm and x<dum){
	     	dumm <- x + 0.1;
	     	second_best <-agent(p.sender).name;
	     }
			  remove p.sender from: list(participantsDecidedToJoin[participantListIndex]);
		}
	   
	    do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: [("Item sold to "+first_best+" for second best price, bidded by "+second_best+" for "+dumm+". The actual bidded price by "+first_best+" is "+dum),"Ends",self,participantListIndex] ];
	  itemsold<-true;
	  // clutch <-true;
	    //do start_conversation with: [ to :: list(participantsDecidedToJoin[participantListIndex]), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [("Inform: ENDS: "+self.name),"Ends",self,participantListIndex] ];
	}
	
	aspect base {
		draw circle((circleDistance)#m) color: #lightblue depth:1;
		draw circle(1) color: #red depth:4;
	}
}

species security skills:[fipa]{
 //bool goingToAuction <- false;
 //point targetPoint <- any_location_in(one_of(security));
 
 //point initPoint <- {(rnd(0,100)),(rnd(0,100)),0};
 
 
 reflex reachSecurity when: reachSecurity{
	int i <- 0;		
			ask participant at_distance 0.5 {
            
          //  write self.name + "Phone signal detector ON!!";
			write self.name + "At Security check";
			
			if(i=0){
			self.phoneOn <-flip(self.phoneOnProbability);
		     i<- i+1;
		     }
		    			
			if(!self.phoneOn){
			
			self.targetPoint <- any_location_in(one_of(initiator));
			self.goingToAuction <- true;
			}
			else
			{
			write self.name + "Please switch of your phone. This is a silent sealed bid auction";
			write self.name + "Oh sorry! I switched it off now!";
			//self.targetPoint <- initPoint;
			self.phoneOn <- false;
			self.targetPoint <- any_location_in(one_of(initiator));
			self.goingToAuction <- true;	
			}
			
			}
		}
		
 
 
 aspect base {
		
		draw circle(1) color: #black depth:4;
	} 	
}


species participant skills: [fipa,moving] {
	
	//random value of half of the first initiatior.
	bool phoneOn <- false;
	float phoneOnProbability <- 0.5;
	bool sat_bid_price <- false;
	bool sat_bid_neg <- false;
	int maxPrice <- 0;
	int i_have <-0;
	bool busy <- false;
	bool gotFirstProposal <- false;
	bool goingToAuction <- false;
	int firstProposal;
	string interestItem <- "Clothes";
	int participantListIndex;
	int mymax <-0;
	point initPoint <- {(rnd(0,100)),(rnd(0,100)),0};
	bool snack<-false;
	point targetPoint <- nil;
	
	

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
		reflex receive_startInfo_from_initiator when: !empty(informs) and !busy  {
		//write "lengthofInformsinside"+length(informs);    		
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
			reachSecurity <-true;
			self.targetPoint <- any_location_in(one_of(security));
			
			//self.targetPoint <- {(targetPoint.x-rnd(1,circleDistance/2)),(targetPoint.y-rnd(circleDistance/2)),targetPoint.z};
			//self.goingToAuction <- true;
			
		}	
		}
		
		
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
		
		maxPrice <- rnd(firstProposal, 10000, 100);
	    
     	sat_bid_price <- true;
		}
	
			write '\t' + name + ' sends a propose message to ' + agent(proposalFromInitiator.sender).name +self.maxPrice;
			//mymax<-self.maxPrice;
			do propose with: [ message :: proposalFromInitiator, contents :: ['I will buy '+self.interestItem+' for -',self.maxPrice, self.name] ];
	
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
			species security aspect:base;
			}
	}
}

