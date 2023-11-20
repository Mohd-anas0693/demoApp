import Principal "mo:base/Principal";

import CA "mo:candb/CanisterActions";
import CanDB "mo:candb/CanDB";
import Entity "mo:candb/Entity";

shared ({ caller = owner }) actor class Data({
    partitionKey : Text;
    scalingOptions : CanDB.ScalingOptions;
    owners : ?[Principal];}
) {
    stable let db = CanDB.init({
        pk = partitionKey;
        scalingOptions = scalingOptions;
        btreeOrder = null;
    });

    //func to get the partition Key 
    public query func getPK() : async Text { db.pk };

    //required api
    public query func skExists(sk : Text) : async Bool {
        CanDB.skExists(db, sk);
    };

    // transfer cycles public api
    public shared ({ caller = caller }) func transferCycles() : async () {
        if (caller == owner) {
            return await CA.transferCycles(caller);
        };
    };

    //function to put the data
    public func putData(sk : Text, key:Text,value : Text) : async () {
        if (sk == "" or value == "") { return };
        await* CanDB.put(db, { 
            sk = sk; 
            attributes = [
                ("keyvalue", #text(value))
                ]
            });
    };

};
