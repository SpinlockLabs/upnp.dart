///This is a testing file for a superset of methods to use for the media and AVTransport service of UPnP devices
///




import "package:upnp/upnp.dart";
import 'package:xml/xml.dart' as xml;
import 'package:strings/strings.dart';
import 'dart:convert' show HtmlEscape, HtmlEscapeMode;
main() async{


  Future<Map<String, dynamic>> getCurrentMediaInfo({Service service}) async{
    return await service.invokeAction("GetMediaInfo", {
      "InstanceID":"0"
    });
  }

  Future<Map<String, dynamic>> pauseCurrentMedia({Service service}) async{
    return await service.invokeAction("Pause", {
      "InstanceID":"0"
    });
  }

  Future<Map<String, dynamic>> playCurrentMedia({Service service, String Speed}) async{
    return await service.invokeAction("Play", {
      "InstanceID":"0",
      "Speed":Speed??"1"
    });
  }

  Future<Map<String, dynamic>> stopCurrentMedia({Service service}) async{
    return await service.invokeAction("Stop", {
      "InstanceID":"0",
    });
  }

  Future<Map<String, dynamic>> getTransportSettings({Service service}) async{
    return await service.invokeAction("GetTransportSettings", {
      "InstanceID":"0"
    });
  }
  Future<Map<String, dynamic>> getPositionInfo({Service service}) async{
    return await service.invokeAction("GetPositionInfo", {
      "InstanceID":"0"
    });
  }

  ///Return the current status of the playback
  ///Example : {CurrentTransportState: PAUSED_PLAYBACK, CurrentTransportStatus: OK, CurrentSpeed: 1}
  Future<Map<String, dynamic>> getTransportInfo({Service service}) async{
    return await service.invokeAction("GetTransportInfo", {
      "InstanceID":"0"
    });
  }


  ///Returns the device capabilities from playing and recording
  ///Example : {PlayMedia: NONE,NETWORK,HDD,CD-DA,UNKNOWN, RecMedia: NOT_IMPLEMENTED, RecQualityModes: NOT_IMPLEMENTED}
  Future<Map<String, dynamic>> getDeviceCapabilities({Service service}) async{
    return await service.invokeAction("GetDeviceCapabilities", {
      "InstanceID":"0"
    });
  }

  ///Returns the possible transport actions that can be called
  ///Example : {Actions: Play,Pause,Stop,Seek,Next,Previous}
  Future<Map<String, dynamic>> getTransportActions({Service service}) async{
    return await service.invokeAction("GetCurrentTransportActions", {
      "InstanceID":"0"
    });
  }

  ///Sets teh PlayMode to playmode argument
  ///Play Modes are one of the following :
  /// NORMAL :
  /// SHUFFLE :
  /// REPEAT_ONE :
  /// REPEAT_ALL :
  /// RANDOM :
  /// DIRECT_1 : Will only play the first track then completely stop
  /// INTRO : Will only play 1à seconds of each track then stop after playing (the 10 seconds) all of the tracks
  Future<Map<String, dynamic>> setPlayMode({Service service, String playmode}) async{
    return await service.invokeAction("GetCurrentTransportActions", {
      "InstanceID":"0",
      "NewPlayMode":playmode??"NORMAL"
    });
  }

  ///Will set the next item in the playlist To be early buffered
  ///[Objectclass] is a the type definition of the item to be played it can be of the following :
  /// - object.item.imageItem
  /// - object.item.audioItem
  /// - object.item.videoItem
  /// - object.item.playlistItem
  /// - object.item.textItem
  /// - object.item.bookmarkItem
  /// - object.item.epgItem
  ///
  /// Please visit the following source for more information
  /// Source : https://www.researchgate.net/figure/UPnP-DIDL-Lite-Metadata-Model-Listing-1-Abstract-DID-Model-The-abstract-DID-model-has_fig1_237063436
  ///
  /// [creator] is equivalent to author or artist and is just a string
  /// [uri] is the uri for the file, it should be public and accessible over http ( this is not a final version )
  Future<Map<String, dynamic>> setNextURI({Service service, String uri, String artUri, String title, String creator,
    String Objectclass, String Duration, String Album ,int Size, String region, String genre, int trackNumber}) async{
    HtmlEscape htmlEscape = const HtmlEscape();

    return await service.invokeAction("SetNextAVTransportURI", {
      "InstanceID":"0",
      "NextURI":uri??"",
      "NextURIMetaData":(htmlEscape.convert(xml.parse('<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sec="http://www.sec.co.kr/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
          '<item id="0" parentID="-1" restricted="false">'
          '<upnp:class>${Objectclass??"object.item.audioItem.musicTrack"}</upnp:class>'
          '<dc:title>${title??"Unknown Title"}</dc:title>'
          '<dc:creator>${creator??"Unknown creator"}</dc:creator>'
          '<upnp:artist>${creator??"Unknown Artist"}</upnp:artist>'
          '<upnp:album>${Album}</upnp:album>'
          '<upnp:originalTrackNumber>${trackNumber??1}</upnp:originalTrackNumber>'
          '<dc:genre>${genre}</dc:genre>'
          '<upnp:albumArtURI dlna:profileID="JPEG_TN" xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/">${artUri}</upnp:albumArtURI>'
          '<res duration="${Duration}" size="${Size}" protocolInfo="http-get:*:audio/mpeg:DLNA.ORG_PN=MP3;DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01700000000000000000000000000000">${uri}</res>'
          '</item>'
          '</DIDL-Lite>').toString()))
    });
  }


  ///This will override the current URI
  ///
  ///[Objectclass] is a the type definition of the item to be played it can be of the following :
  /// - object.item.imageItem
  /// - object.item.audioItem
  /// - object.item.videoItem
  /// - object.item.playlistItem
  /// - object.item.textItem
  /// - object.item.bookmarkItem
  /// - object.item.epgItem
  ///
  /// Please visit the following source for more information
  /// Source : http://www.upnp.org/schemas/av/upnp.xsd
  ///
  /// [creator] is equivalent to author or artist and is just a string
  /// [uri] is the uri for the file, it should be public and accessible over http ( this is not a final version )
  Future<Map<String, dynamic>> SetCurrentURI({Service service, String uri, String artUri, String title, String creator,
    String Objectclass, String Duration, String Album ,int Size, String region, String genre, int trackNumber}) async{

    HtmlEscape htmlEscape = const HtmlEscape();

    return await service.invokeAction("SetAVTransportURI", {
      "InstanceID":"0",
      "CurrentURI":uri??"",
      "CurrentURIMetaData":(htmlEscape.convert(xml.parse('<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sec="http://www.sec.co.kr/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
          '<item id="0" parentID="-1" restricted="false">'
          '<upnp:class>${Objectclass??"object.item.audioItem.musicTrack"}</upnp:class>'
          '<dc:title>${title??"Unknown Title"}</dc:title>'
          '<dc:creator>${creator??"Unknown creator"}</dc:creator>'
          '<upnp:artist>${creator??"Unknown Artist"}</upnp:artist>'
          '<upnp:album>${Album}</upnp:album>'
          '<upnp:originalTrackNumber>${trackNumber??1}</upnp:originalTrackNumber>'
          '<dc:genre>${genre}</dc:genre>'
          '<upnp:albumArtURI dlna:profileID="JPEG_TN" xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/">${artUri}</upnp:albumArtURI>'
          '<res duration="${Duration}" size="${Size}" protocolInfo="http-get:*:audio/mpeg:DLNA.ORG_PN=MP3;DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01700000000000000000000000000000">${uri}</res>'
          '</item>'
          '</DIDL-Lite>').toString()))
    });
  }

  Future<Map<String, dynamic>> goToPrevious({Service service}) async{
    return await service.invokeAction("Previous", {
      "InstanceID":"0"
    });
  }

  Future<Map<String, dynamic>> goToNext({Service service}) async{
    return await service.invokeAction("Next", {
      "InstanceID":"0"
    });
  }

  ///Seeks the current playing track to a specific position
  ///[position] is an absolute value and needs to be in this format : HH:MM:SS
  ///where HH is hours, MM is minutes and SS is seconds
  ///Example : 00:01:00
  Future<Map<String, dynamic>> seekPostion({Service service, double position}) async{
    return await service.invokeAction("Seek", {
      "InstanceID":"0",
      "Unit":"REL_TIME",
      "Target":position??"00:01:00"
    });
  }

  var disc = new DeviceDiscoverer();
  await disc.start(ipv6: false);
  disc.quickDiscoverClients().listen((client) async {
    try {
      var dev = await client.getDevice();
      print(dev.friendlyName);

      /*print("${dev.friendlyName}: ${dev.url}");
      dev.services.forEach((service) async{
        print("The actions names for the service ${service.type} : ${(await service.getService(dev)).actionNames}");
      });*/
      var result = await dev.getService("urn:schemas-upnp-org:service:AVTransport:1");
      if(result!=null){

       // print(dev.url);
      }
      if(result!=null){


        Service serv = result;
        serv.actions.forEach((actionElem){
            print(actionElem.name);
            print(actionElem.arguments.map((el)=>el.name));
          });





        SetCurrentURI(service: serv,
            title: "LOLO",
            creator: "LOLOLO",
            Objectclass: "object.item.audioItem",
            uri: "http://192.168.1.6:8090/AT1983/I%20CAN%27T%20STOP%20THE%20LONELINESS.mp3",
            Album: "No Album",
          genre: "Jpop",
          trackNumber: 1,
        ).then(
                (data){
              print(data);
              playCurrentMedia(service: serv).then((x){
                getCurrentMediaInfo(service: serv).then((meDiaData){
                  print(meDiaData);
                });
              });
            }
        );

        /*var resss = serv.invokeAction("GetMediaInfo", {
            "InstanceID":"0"
          }).then((data){
            print(data);
          });
          //pauseCurrentMedia(service: serv);
          getTransportSettings(service: serv).then(
              (data){
                print(data);
              }
          );*/

        /*getCurrentMediaInfo(service: serv).then((data){
            print(data);
          });*/


      }
      /*dev.services.forEach((elem)async{
        print(elem.id);
      });*/
    } catch (e, stack) {
      print("ERROR: ${e} - ${client.location}");
      print(stack);
    }
  });



}