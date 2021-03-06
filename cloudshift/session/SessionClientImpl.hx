
package cloudshift.session;

import cloudshift.Core;
import cloudshift.Session;
using cloudshift.Mixin;

private class SessionProxy extends haxe.remoting.AsyncProxy<cloudshift.session.SessionMgrProxy> { }

class SessionClientImpl implements Part<Dynamic,String,SessionClient,ESession>,implements SessionClient {
  var _sessID:String;
  var _proxy:SessionProxy;
  var _stash:Hash<Dynamic>;
  
  public var part_:Part_<Dynamic,String,SessionClient,ESession>;

  public function new() {
    part_ = Core.part(this);
  }

  public function
  start_(d:Dynamic,?oc:Outcome<String,SessionClient>) {
    if (oc == null)
      oc = Core.outcome();
    var cnx = haxe.remoting.HttpAsyncConnection.urlConnect("http://"+js.Lib.window.location.host+Session.REMOTE);
    cnx.setErrorHandler( function(err) trace("Error : "+Std.string(err)) );
    _proxy = new SessionProxy(cnx.Auth);
    oc.resolve(Right(cast this));
    return oc;
  }

  function doLogin(p:Outcome<String,String>,e:ESession) {
    switch(e) {
    case UserOk(sid):
      _sessID = sid;
      trace("set sessID ok");
      p.resolve(Right(_sessID));
    default:
      p.resolve(Left(Std.string(e)));
    }
    notify(e);
  }

  public function
  login(pkt:Dynamic):Outcome<String,String> {
    var p = Core.future();
    _proxy.login(pkt,callback(doLogin,p));
    return p;
  }

  public function
  signup(pkt):Outcome<String,String> {
    var p = Core.future();
    _proxy.signup(pkt,callback(doLogin,p));
    return p;
  }

  public function
  logout():Outcome<String,String> {
    var p = Core.future();
    _proxy.logout(_sessID,function(e:ESession) {
        switch(e) {
        case UserRemoved:
          p.resolve(Right(""));
        default:
          p.resolve(Left("Can't remove user:"+Std.string(e)));
        }
        _sessID = null;
        notify(e);
      });
    return p;
  }
  
  public function sessID() { return _sessID; }

}