
package cloudshift;

import cloudshift.Core;

#if CS_SERVER
import cloudshift.Http;
#end

enum ESession {
  UserOk(sessID:String);
  UserNoUser;
  UserExists;
  UserRemoved;
}

enum ESessionOp {
  Login(pkt:Dynamic,cb:ESession->Void) ;
  Logout(sessID:String,cb:ESession->Void) ;
  Signup(pkt:Dynamic,cb:ESession->Void) ;
}

#if CS_SERVER

interface SessionMgr implements Part<HttpServer,String,SessionMgr,ESessionOp> {
  function authorize(cb:ESessionOp->Void):Void->Void;
  function exists(sessID:String,cb:Bool->Void):Void;
  function logout(sessID:String,cb:ESession->Void):Void;
  function http():HttpServer;
}

#elseif CS_BROWSER

interface SessionClient implements Part<Dynamic,String,SessionClient,ESession> {
  /**
     ErrMsg on Left
     SessionID on Right
   */
  function login(pkt:Dynamic):Outcome<String,String>;
  function logout():Outcome<String,String>;
  function signup(pkt:Dynamic):Outcome<String,String>;
  function sessID():String;
}

#end

class Session {

  
  public static var REMOTE = Core.CSROOT+"__r";
  
  #if CS_SERVER
  public static function
  manager():SessionMgr {
    return new cloudshift.session.SessionMgrImpl();
  }
  #elseif CS_BROWSER
  public static function
  client() {
    return new cloudshift.session.SessionClientImpl();
  }
  #end

}