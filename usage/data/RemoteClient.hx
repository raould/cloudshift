
import cloudshift.Core;
import cloudshift.Data;
import cloudshift.Http;

using cloudshift.Mixin;

class RemoteClient {

  public static function main(){
     Data.store(REMOTESQLITE("http://localhost:8082/data")).deliver(function(store) {
        store.bucket("woot").deliver(function(woot) {
           
            woot.where('name="lore"').deliver(function(recs) {
                trace(recs.stringify());
              });
            
            woot.insert({email:"lorena@ritchie.com",name:"lore",passwd:"and why not"})
              .deliver(function(u) {
                  trace("lore's id = "+Data.oid(u));
              });
          });

        store.hash("peeps").deliver(function(peeps) {
            peeps.set("me",{email:"lorena@ritchie.com",name:"lore",passwd:"and why not"})
              .deliver(function(p) {
                  peeps.get("me").deliver(function(me) {
                      if (me.name == "lore")
                        trace("yep got it");
                    });
                });
          });
       });
  }
}