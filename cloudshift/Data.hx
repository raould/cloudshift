
package cloudshift;

import cloudshift.Core;

#if DATAONLINE
import cloudshift.Http;
import cloudshift.Remote;
import cloudshift.data.RemoteBucketProxy;
#end

interface Store {
  function bucket<T>(bucketName:String):Outcome<String,Bucket<T>>;
  function hash<T>(bucketName:String):Outcome<String,BHash<T>>;
  function name():String;
  function lookupBucket<T>(bucketName:String):Option<Bucket<T>>;
}

interface Bucket<T> {
  function insert(obj:T):Outcome<String,T>;
  function update(obj:T):Outcome<String,T>;
  function delete(obj:T):Outcome<String,T>;

  function getByOid(id:Int):Outcome<String,T>;
  function deleteByOid(id:Int):Outcome<String,Int>;

  function indexer(name:String,cb:Indexer<T>,?typeHint:String,?unique:Bool):Outcome<String,Bool>;
  function index():Outcome<String,Bool>;
  function where(where:String):Outcome<String,Array<T>>;
  function find(query:Dynamic):Outcome<String,Array<T>>;

  function link(bucketValue:BucketValue,obj:T):Outcome<String,Bool>;
  function child(obj:Dynamic):BucketValue;
  function linked<Q>(bucket:Bucket<Q>,val:T):Outcome<String,Option<Array<Q>>>;
  function unlink(child:BucketValue,parent:T):Outcome<String,Bool>;

  function store():Store;
  function name():String;
}

typedef BucketValue = { bucket:String,oid:Dynamic };

interface BHash<T> {
  function get(key:String):Outcome<String,T>;
  function set(key:String,val:T):Outcome<String,T>;
  function remove(key:String):Outcome<String,String>;
  function keys(?like:String):Outcome<String,Array<String>>;
  function values(?like:String):Outcome<String,Array<T>>;
}

typedef Indexer<T> = T->Dynamic;

enum StoreKind {
  SQLITE(name:String);
  REMOTESQLITE(url:String);
}


class Data {
  public static function store<T>(kind:StoreKind):Future<Store> {
    var p = Core.future();
    switch(kind) {
    case SQLITE(name):
      #if nodejs
      new cloudshift.data.Sqlite3Store(p,name);
      #end
    case REMOTESQLITE(url):
      #if DATAONLINE
      new cloudshift.data.RemoteSqlite3Client(p,url);
      #end
    }
    return p;
  }

  #if DATAONLINE
  public static function bucketOnline<T>(http:HttpServer,bucket:Bucket<T>,url:String) {
    var rem = Remote.provider("Store",new RemoteBucketProxy(bucket));
    http.handler(new EReg(url+bucket.name(),""),rem.httpHandler);
  }
  #end
  
  public static function oid(pkt:Dynamic):Null<Int> {
    return Reflect.field(pkt,"__oid");
  }

}
