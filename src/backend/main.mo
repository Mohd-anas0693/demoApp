import CanisterMap "mo:candb/CanisterMap";
import Utils "mo:candb/Utils";
import Buffer "mo:stablebuffer/StableBuffer";
import CA "mo:candb/CanisterActions";


import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Cycles "mo:base/ExperimentalCycles";

import index "index";
shared ({caller=owner})actor class IndexCansiter()=this{
type ActorType=actor{
  getPk: ()  -> async Text;
  skExists:(sk:Text) -> async Bool;
  putData: (sk:Text,key:Text,value:Text) -> async ();
};

  stable var pkToCanisterMap = CanisterMap.init();

  func getCanisterIdsIfExists(pk:Text):[Text]{
    switch(CanisterMap.get(pkToCanisterMap,pk)){
      case null {[]};
      case (?canisterIdsBuffer){ Buffer.toArray(canisterIdsBuffer)};
    };
  };

  public  shared query({caller=caller}) func getCanisterByPK(pk:Text):async [Text]{
    getCanisterIdsIfExists(pk);
  };

  public shared ({caller=caller }) func autoScaleCanister(pk:Text):async Text{
      if(Utils.callingCanisterOwnsPK(caller,pkToCanisterMap,pk)){
        Debug.print("create an additional Canister for the PK= " # pk);
      await createCanister(pk,?[owner,Principal.fromActor(this)]);
      }
      else{
        throw Error.reject("not authorised");
      };
  } ;

 func createCanister(pk:Text,controllers:?[Principal]):async Text{
  Debug.print("create new canster services canister with Pk="#pk);
  Cycles.add(300_000_000_000);
  let newCanister = await index.Data({
      partitionKey = pk;
      scalingOptions = {
        autoScalingHook = autoScaleCanister;
        sizeLimit = #heapSize(475_000_000); // Scale out at 475MB
        // for auto-scaling testing
        //sizeLimit = #count(3); // Scale out at 3 entities inserted
      };
  owners=controllers;
    });
  let newCanisterPrincipal=Principal.fromActor(newCanister);
  await CA.updateCanisterSettings({canisterId = newCanisterPrincipal;
      settings = {
        controllers = controllers;
        compute_allocation = ?0;
        memory_allocation = ?0;
        freezing_threshold = ?2592000;
      };
    });

  let newCanisterId=Principal.toText(newCanisterPrincipal);
  
  pkToCanisterMap := CanisterMap.add(pkToCanisterMap,pk,newCanisterId);
  
  Debug.print("new service CanisterId=" # newCanisterId);
  
  newCanisterId
 };

 
};
