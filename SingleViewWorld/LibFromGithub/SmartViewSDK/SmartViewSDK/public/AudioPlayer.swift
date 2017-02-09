/*

Copyright (c) 2015 Samsung Electronics

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/
import Foundation

//MARK: AudioPlayerDelegate
@objc public protocol AudioPlayerDelegate: class
{

    //MARK: All Optional Callbacks
    /**
      event occurs on Buffering of Audio Start.
    */
    @objc optional func onBufferingStart()
    /**
      event occurs on Buffering of Audio Complete.
    */
    @objc optional func onBufferingComplete()
    /**
       event occurs asynchronously when audio buffering is in progress.
     
     - parameter progress: current Buffer Progerss
    */
    @objc optional func onBufferingProgress(_ progress: Int)
    /**
       event occurs continously when Audio streaming is going on.
     
     - parameter progress: current playing time of Audio.
    */
    @objc optional func onCurrentPlayTime(_ progress: Int)
    /**
     event occurs when Audio streaming start.
     
     - parameter duration: total duration of audio.
    */
    @objc optional func onStreamingStarted(_ duration: Int)
    /**
     event occurs when Audio streaming completed.
    */
    @objc optional func onStreamCompleted()
    /**
     event occurs when Audio is shared with TV for the first time.
    */
    @objc optional func onPlayerInitialized()
    /**
     event occurs when different type of media is shared with TV.
     (Audio is shared after photo/video share)
     
     - parameter playerType: current player type (photo/audio/video)
    */
    @objc optional func onPlayerChange(_ playerType: String)
    
    /**
     event occurs when paused audio is played.
    */
    @objc optional func onPlay()
    /**
     event occurs on audio pause.
    */
    @objc optional func onPause()
    /**
     event occurs on audio stop.
    */
    @objc optional func onStop()
    /**
     event occurs on Player mute.
    */
    @objc optional func onMute()
    /**
     event occurs on Player unMute.
    */
    @objc optional func onUnMute()
    /**
     event occurs when Player plays next content.
     */
    @objc optional func onNext()
    
    /**
     event occurs when Player plays previous content.
     */
    @objc optional func onPrevious()
    
    /**
     provides the status of play controls like volume, mute/unmute and mode of player like single or repeat all
     - parameter volLevel:      player volume level
     - parameter muteStatus:    player mute status
     - parameter shuffleStatus: player shuffle status
     - parameter mode:          player mode single or repeat all
    */
    @objc optional func onControlStatus(_ volLevel: Int, muteStatus: Bool, shuffleStatus: Bool, mode: String)
    /**
       event occurs on  player volume change.
     
     - parameter volLevel: player volume to be set.
    */
    @objc optional func onVolumeChange(_ volLevel: Int)
    
    /**
       event occurs on audio addition in TV queue(player list).
     
     - parameter enqueuedItem:  enqueued audio item.
    */
    @objc optional func onAddToList(_ enqueuedItem: [String: AnyObject])
    /**
       event occurs on audio remove from TV queue(player list).
     
     - parameter dequeuedItem: dequeued audio Item.
    */
    @objc optional func onRemoveFromList(_ dequeuedItem: [String: AnyObject])
    /**
     event occurs on TV queue(player list) deletion.
    */
    @objc optional func onClearList()
    /**
       event occurs when player list(TV queue) is recieved.
     
     - parameter queueList: play list of TV
    */
    @objc optional func onGetList(_ queueList: [String: AnyObject])
    /**
       event occurs when player list is shuffled.
     
     - parameter status: shuffle status(true/false)
    */
    @objc optional func onShuffle(_ status: Bool)
    /**
       event occurs on player list repeat.
     
     - parameter mode:  specify repeat all/repeat single audio
    */
    @objc optional func onRepeat(_ mode: String)
    
    /**
       occurs when new audio is shared with TV.
     
     - parameter currentItem: current shared item.
    */
    @objc optional func onCurrentPlaying(_ currentItem: [String: AnyObject])
    /**
     occurs when TV Application/widget goes into background.
    */
    @objc optional func onApplicationSuspend()
    /**
     occurs when  TV Application/widget comes in foreground.
    */
    @objc optional func onApplicationResume()
    /**
     occurs when error is occured in playing Audio
     
     - parameter error: eror details
    */
    @objc optional func onError(_ error: NSError)
}

//MARK: AudioPlayer Class
/// Audio Player Class handle the Audio share,control and TV Player queue.
@objc open class AudioPlayer: BasePlayer
{
    /// The Audio Player delegate protocol defines the event methods available for a Audio.
    open weak var playerDelegate: AudioPlayerDelegate? = nil
    fileprivate var additionalData = [String: AnyObject]()
    
    /**
     Audio Player Attributes
     
     - title:      title
     - albumName:  album name
     - albumArt:   album art
     */
    fileprivate enum AudioPlayerAttributes: String
    {
        case title                          = "title"
        case albumName                      = "albumName"
        case albumArt                       = "albumArt"
    }
    
    /**
     Audio Player state
     
     - streamcompleted:   stream completed
     - currentplaytime:   current play time
     - totalduration:     total duration
     - bufferingstart:    buffering start
     - bufferingprogress: buffering progress
     - bufferingcomplete: buffering complete
     */
    fileprivate enum AudioPlayerInternalEvents: String
    {
        case streamcompleted                = "streamcompleted"
        case currentplaytime                = "currentplaytime"
        case totalduration                  = "totalduration"
        case bufferingstart                 = "bufferingstart"
        case bufferingprogress              = "bufferingprogress"
        case bufferingcomplete              = "bufferingcomplete"
    }
    
    /**
     defines player control state like play , pause, stop etc
     
     - PLAYER_CONTROL_RESPONSE:     player controls
     - PLAYER_INTERNAL_RESPONSE:    player buffering response
     - PLAYER_QUEUE_EVENT_RESPONSE: player queue events like add, remove , clear etc.
     */
    internal enum PlayerTags: String
    {
        case PLAYER_CONTROL_RESPONSE                      = "state"
        case PLAYER_INTERNAL_RESPONSE                     = "Audio State"
        case PLAYER_QUEUE_EVENT_RESPONSE                  = "queue"
    }
    
    /**
       Initialize audio player object
     
     - parameter mediaplayer: audio player
     */
    internal override init(mediaplayer: MediaPlayer)
    {
        super.init(mediaplayer: mediaplayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AudioPlayer.onMessage(_:)), name: NSNotification.Name(rawValue: MediaPlayer.PlayerNotification.onMessage.rawValue), object: nil)
    }
    
    /**
       A convenience method to unsubscribe from notifications.
    */
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
//MARK: Public APIs- objective C compatible
    /**
      this method play Audio content on TV.
    
    - parameter contentURL:        Audio Url
    - parameter completionHandler: The response completion closure, it will be executed in the request queue i.e. in a backgound thread.
    */
    @objc open func playContent(_ contentURL: URL, completionHandler: ((NSError?) -> Void)? = nil)
    {
        playContent(contentURL, title: "", albumName: "", albumArtUrl: URL(fileURLWithPath: ""), completionHandler: completionHandler)
    }
    
    /**
       play Audio content on TV.
     
     - parameter contentURL:        Content URL
     - parameter title:             Content Title
     - parameter albumName:         Content album name
     - parameter albumArtUrl:       Content thumbnail URL
     - parameter completionHandler: The response completion closure, it will be executed in the request queue i.e. in a backgound thread.
     */
    
    @objc open func playContent(_ contentURL: URL?, title: String, albumName: String, albumArtUrl: URL?, completionHandler: ((NSError?) -> Void)? = nil)
    {
        
        let json:[String: AnyObject]
        if let URL_thumbnail = albumArtUrl , let URL_content = contentURL
        {
            json = [
                MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : URL_content.absoluteString as AnyObject,
                AudioPlayerAttributes.title.rawValue : title as AnyObject,
                AudioPlayerAttributes.albumName.rawValue : albumName as AnyObject,
                AudioPlayerAttributes.albumArt.rawValue : URL_thumbnail.absoluteString as AnyObject
            ]
        }
        else if let URL_content = contentURL
        {
            json = [
                MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : URL_content.absoluteString as AnyObject,
                AudioPlayerAttributes.title.rawValue : title as AnyObject,
                AudioPlayerAttributes.albumName.rawValue : albumName as AnyObject,
                AudioPlayerAttributes.albumArt.rawValue : "" as AnyObject
                
            ]
        }
        else if let URL_thumbnail = albumArtUrl
        {
            json = [
                MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : "" as AnyObject,
                AudioPlayerAttributes.title.rawValue : title as AnyObject,
                AudioPlayerAttributes.albumName.rawValue : albumName as AnyObject,
                AudioPlayerAttributes.albumArt.rawValue : URL_thumbnail.absoluteString as AnyObject
            ]
        }
        else
        {
            json = [
                MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : "" as AnyObject,
                AudioPlayerAttributes.title.rawValue : title as AnyObject,
                AudioPlayerAttributes.albumName.rawValue : albumName as AnyObject,
                AudioPlayerAttributes.albumArt.rawValue : "" as AnyObject
            ]
        }
        
        additionalData = json
        
        mPlayer.playContent(json, type: PlayerTypes.AUDIO, completionHandler: completionHandler)
        
    }
    
    /**
      Seek the given time in currently playing media.
    
    - parameter time: Time in seconds within length of currently playing media.
    */
    @objc open func seek(_ time: TimeInterval)
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: "seekTo:\(Int(time))" as AnyObject?)
    }
    
    /**
       resumes TV widget/application from background process.
     
     - parameter completionHandler: The response completion closure, it will be executed in the request queue i.e. in a backgound thread.
     */
    @objc open func resumeApplicationInForeground(_ completionHandler: ((NSError?) -> Void)? = nil)
    {
        mPlayer.sendStartDMPApplication(PlayerTypes.AUDIO, completionHandler: completionHandler)
    }
    
    //MARK: Queue Implementation
    
    /**
      repeat player list.
    */
    @objc open func `repeat`()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.Repeat.rawValue as AnyObject?)
    }
    
    /**
     shuffle player list.
    */
    @objc open func shuffle()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.shuffle.rawValue as AnyObject?)
    }
    
    /**
      request player list i.e currently playing on TV.
    */
    @objc open func getList()
    {
        let json:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue : PlayerQueueSubEvents.fetch.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.AUDIO.rawValue as AnyObject
        ]
        
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_QUEUE_EVENT, data: json as AnyObject?)
    }
    
    /**
       request to delete(removeAll) player list.
    */
    @objc open func clearList()
    {
        let json:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue : PlayerQueueSubEvents.clear.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.AUDIO.rawValue as AnyObject
        ]
        
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_QUEUE_EVENT, data: json as AnyObject?)
    }
    
    /**
       remove specific audio from player list.
     
     - parameter contentURL: Audio URL
     */
    @objc open func removeFromList(_ contentURL: URL)
    {
        let json:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue : PlayerQueueSubEvents.dequeue.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.AUDIO.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : contentURL.absoluteString as AnyObject
        ]
        
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_QUEUE_EVENT, data: json as AnyObject?)
    }
    
    /**
       Add Audio item to player list.
     
     - parameter contentURL:   URL
     - parameter title:        Title
     - parameter albumName:    Album NAme
     - parameter albumArtUrl:  thumbnail URL
    */
    @objc open func addToList(_ contentURL: URL, title: String = "", albumName: String = "", albumArtUrl: URL = URL(fileURLWithPath: ""))
    {
        let dict:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : contentURL.absoluteString as AnyObject,
            AudioPlayerAttributes.title.rawValue : title as AnyObject,
            AudioPlayerAttributes.albumName.rawValue : albumName as AnyObject,
            AudioPlayerAttributes.albumArt.rawValue : albumArtUrl.absoluteString as AnyObject
            
        ]
        
        addToList([dict])
    }
    
    /**
       Add Audio item to player list.
     
     - parameter arrayDictofData: list data in form array of dictionary
     */
    @objc public func addToList(_ arrayDictofData: [[String: AnyObject]])
    {
        var arrayDictofData = arrayDictofData
        
        if mPlayer.connected
        {
            
            Log.debug("player connected")
            
            mPlayer.isMediaPlayerRunning(
                {(error, status) -> Void in
                    if error == nil && status != nil
                    {
                        for dataDict in arrayDictofData
                        {
                            if let data = self.formRequest(dataDict)
                            {
                                //Aseem - Publish
                                self.mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_QUEUE_EVENT, data: data as AnyObject?)
                            }
                            
                        }
                    }
                    else
                    {
                        Log.debug("Mediaplayer is not running")
                    }
            })
        }
        else
        {
            Log.debug("player not connected")
            
            let data = arrayDictofData.remove(at: 0)
            
            var contentURL: URL
            var thumbURL: URL?
            var title: String?
            var albumName: String?
            
            if let contentUrlStr = data[MediaPlayer.PlayerProperty.CONTENT_URI.rawValue]
            {
                contentURL = URL(fileURLWithPath: contentUrlStr as! String)
                
                Log.debug("contentURL is \(contentURL)")
            }
            else
            {
                Log.debug("contentURL is nil")
                return
            }
            
            if (data[AudioPlayerAttributes.title.rawValue] != nil)
            {
                title = data[AudioPlayerAttributes.title.rawValue] as? String
            }
            
            if (data[AudioPlayerAttributes.albumName.rawValue] != nil)
            {
                albumName = data[AudioPlayerAttributes.albumName.rawValue] as? String
            }
            
            if let albumArtStr = data[AudioPlayerAttributes.albumArt.rawValue]
            {
                thumbURL = URL(fileURLWithPath: albumArtStr as! String)
            }
            
            playContent(contentURL, title: title!, albumName: albumName!, albumArtUrl: thumbURL!, completionHandler:
                { (error) -> Void in
                    
                    if error == nil
                    {
                        if arrayDictofData.count != 0
                        {
                            self.mList = arrayDictofData
                        }
                    }
                    else
                    {
                        Log.debug("MediaPlayer: Error Details: error.code=\(error?.code), error.debugDescription=\(error.debugDescription)")
                    }
                    
            })
            
            
        }
        
        
    }
    
    //MARK: Notification Method
    /**
     Notification of any data received from TV player
    
    - parameter notification: contains player queue event and action
    */
    open func onMessage(_ notification: Notification!)
    {
        if  let userInfo = notification.userInfo as? [String : AnyObject]
        {
            self.parseData(userInfo)
        }
    }
    
   //MARK: Private Functions
    /**
      create request for player events
    
    - parameter dataDict: request data dictionary
    
    - returns: json object of created request
    */
    fileprivate func formRequest(_ dataDict: [String: AnyObject]) -> [String: AnyObject]?
    {
        var json:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue : PlayerQueueSubEvents.enqueue.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.AUDIO.rawValue as AnyObject
        ]
        
        if let contentUrlStr = dataDict[MediaPlayer.PlayerProperty.CONTENT_URI.rawValue]
        {
            json.updateValue(contentUrlStr as! String as AnyObject, forKey: MediaPlayer.PlayerProperty.CONTENT_URI.rawValue)
        }
        else
        {
            return nil
        }
        
        if let title = dataDict[AudioPlayerAttributes.title.rawValue]
        {
            json.updateValue(title as! String as AnyObject, forKey: AudioPlayerAttributes.title.rawValue)
        }
        
        if let albumName = dataDict[AudioPlayerAttributes.albumName.rawValue]
        {
            json.updateValue(albumName as! String as AnyObject, forKey: AudioPlayerAttributes.albumName.rawValue)
        }
        
        if let albumArtStr = dataDict[AudioPlayerAttributes.albumArt.rawValue]
        {
            json.updateValue(albumArtStr as! String as AnyObject, forKey: AudioPlayerAttributes.albumArt.rawValue)
        }
        
        return json
        
        
    }
    
    /**
       parsing the data
     
     - parameter data: parsing data to events
     */
    fileprivate func parseData(_ data: [String : AnyObject])
    {        
        if (mPlayer.playerContentType != PlayerTypes.AUDIO.rawValue)
        {
            return;
        }
        
        if let errorStr = data[MediaPlayer.PlayerProperty.PLAYER_ERROR_MESSAGE_EVENT.rawValue]
        {
            if let errorCode = Int(errorStr as! String)
            {
                self.playerDelegate?.onError?(errorWithDetail(errorCode))
            }
            else
            {
                ///Generic Error code - 101 which caters some specific clients
                self.playerDelegate?.onError?(NSError(domain: "PLAYER", code: 101, userInfo: [NSLocalizedDescriptionKey:errorStr as! String]))
            }
        }
        
        if (data[MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue] != nil)
        {
            let subEventData = data[MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue]
            
            if ((subEventData?.isEqual(to: MediaPlayer.PlayerProperty.PLAYER_READY_SUB_EVENT.rawValue)) != nil)
            {
                //Aseem - Publish
                additionalData.updateValue(PlayerTypes.AUDIO.rawValue as AnyObject, forKey: MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue)
                additionalData.updateValue(PlayerContentSubEvents.ADDITIONALMEDIAINFO.rawValue as AnyObject, forKey: MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue)
                mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTENT_CHANGE_EVENT, data: additionalData as AnyObject?)
                
                self.playerDelegate?.onPlayerInitialized?();
            }
            else if ((subEventData?.isEqual(to: MediaPlayer.PlayerProperty.PLAYER_CHANGE_SUB_EVENT.rawValue)) != nil)
            {
                //Check if we have pending AddToList request; & if yes - send the pending list.
                
                if mList?.count != 0
                {
                    sendSubsequenetList()
                }
                
                self.playerDelegate?.onPlayerChange?(PlayerTypes.AUDIO.rawValue)
            }
        }
        else if (data[MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue] != nil) &&
           // let playerType = data[MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue] as! String &&
            (data[MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue] as! String).caseInsensitiveCompare(PlayerTypes.AUDIO.rawValue) == ComparisonResult.orderedSame
        {
            //Handle other events..
            if let play_cont_resp = data[PlayerTags.PLAYER_CONTROL_RESPONSE.rawValue]
            {
                handlePlayerControlResponse(play_cont_resp)
            }
            else if let play_int_resp = data[PlayerTags.PLAYER_INTERNAL_RESPONSE.rawValue]
            {
                handlePlayerInternalResponse(play_int_resp as! String)
            }
            else if let play_queue_resp = data[PlayerTags.PLAYER_QUEUE_EVENT_RESPONSE.rawValue]
            {
                handlePlayerQueueEventResponse(play_queue_resp as! [String:AnyObject])
            }
            else if let play_current_event = data[MediaPlayer.PlayerProperty.PLAYER_CURRENT_PLAYING_EVENT.rawValue]
            {
                self.playerDelegate?.onCurrentPlaying?(play_current_event as! [String:AnyObject])
            }
        }
        
        else
        {
            if let stateOnly = data[PlayerTags.PLAYER_CONTROL_RESPONSE.rawValue]
            {
                if stateOnly is String
                {
                    if stateOnly.contains(PlayerControlEvents.getControlStatus.rawValue)
                    {
                        var volumeLevel = 0
                        var muteStatus = false
                        var shuffleStatus = false
                        var repeatMode = RepeatMode.repeatOff.rawValue
                        
                        if let controlVol = data[PlayerControlStatus.volume.rawValue]
                        {
                            volumeLevel = controlVol as! Int
                        }
                        if let controlMute = data[PlayerControlStatus.mute.rawValue]
                        {
                            if (controlMute is Bool && controlMute as! Bool == true)
                            {
                                muteStatus = true
                            }
                            
                        }
                        if let controlShuffle = data[PlayerControlStatus.shuffle.rawValue]
                        {
                            if (controlShuffle is Bool && controlShuffle as! Bool == true)
                            {
                                shuffleStatus = true
                            }
                        }
                        if let controlRepeat = data[PlayerControlStatus.`repeat`.rawValue]
                        {
                            if controlRepeat is String && (controlRepeat as! String).contains(RepeatMode.repeatAll.rawValue)
                            {
                                repeatMode = RepeatMode.repeatAll.rawValue
                            }
                            else if (controlRepeat as! String).contains(RepeatMode.repeatSingle.rawValue)
                            {
                                repeatMode = RepeatMode.repeatSingle.rawValue
                            }
                            else if (controlRepeat as! String).contains(RepeatMode.repeatOff.rawValue)
                            {
                                repeatMode = RepeatMode.repeatOff.rawValue
                            }
                        }
                        
                        self.playerDelegate?.onControlStatus?(volumeLevel, muteStatus: muteStatus, shuffleStatus: shuffleStatus, mode: repeatMode)
                    }
                    else
                    {
                        handleExtraResponse(stateOnly as! String)
                    }
                }
                
            }
            else if let status = data[MediaPlayer.PlayerProperty.PLAYER_APP_STATUS_EVENT.rawValue]
            {
                let player_status = status as! String
                
                if player_status.caseInsensitiveCompare(PlayerApplicationStatusEvents.suspend.rawValue) == ComparisonResult.orderedSame
                {
                    self.playerDelegate?.onApplicationSuspend?()
                }
                else if player_status.caseInsensitiveCompare(PlayerApplicationStatusEvents.resume.rawValue) == ComparisonResult.orderedSame
                {
                    self.playerDelegate?.onApplicationResume?()
                }
            }
        }
    }
    
    /**
     sending list to TV player
    */
    fileprivate func sendSubsequenetList()
    {
        if mPlayer.connected
        {
            mPlayer.isMediaPlayerRunning({ (error, status) -> Void in
                if error == nil && status != nil
                {
                    for dataDict in self.mList!
                    {
                        if let data = self.formRequest(dataDict)
                        {
                            //Aseem - Publish
                            self.mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT, data: data as AnyObject?)
                        }
                        
                    }
                }
                else
                {
                    Log.debug("Mediaplayer is not running")
                }
            })
        }
    }
    
    /**
     This method controls the response to play , pause or stop
     
     - parameter message: rersponse data
     */
    fileprivate func handlePlayerControlResponse(_ message: AnyObject)
    {
        if message is String
        {
            let mess = message as! String
            if mess.contains(PlayerControlEvents.play.rawValue)
            {
                self.playerDelegate?.onPlay?()
            }
            else if mess.contains(PlayerControlEvents.pause.rawValue)
            {
                self.playerDelegate?.onPause?()
            }
            else if mess.contains(PlayerControlEvents.stop.rawValue)
            {
                self.playerDelegate?.onStop?()
            }
            else if mess.contains(PlayerControlEvents.next.rawValue)
            {
                self.playerDelegate?.onNext?()
            }
            else if mess.contains(PlayerControlEvents.previous.rawValue)
            {
                self.playerDelegate?.onPrevious?()
            }
        }
        else
        {
            let messageDict = message as! [String:AnyObject]
            if let value = messageDict[PlayerControlEvents.Repeat.rawValue]
            {
                if (value as! String).contains(RepeatMode.repeatAll.rawValue)
                {
                    self.playerDelegate?.onRepeat?(RepeatMode.repeatAll.rawValue)
                }
                else if (value as! String).contains(RepeatMode.repeatSingle.rawValue)
                {
                    self.playerDelegate?.onRepeat?(RepeatMode.repeatSingle.rawValue)
                }
                else if (value as! String).contains(RepeatMode.repeatOff.rawValue)
                {
                    self.playerDelegate?.onRepeat?(RepeatMode.repeatOff.rawValue)
                }
            }
            else if let value = messageDict[PlayerControlEvents.shuffle.rawValue]
            {
                if value as! Bool
                {
                    self.playerDelegate?.onShuffle?(true)
                }
                else
                {
                    self.playerDelegate?.onShuffle?(false)
                }
            }
        }
        
    }
    
    /**
       handle response to event
     
     - parameter message: response contains player state like buffering and streaming state
    */
    fileprivate func handlePlayerInternalResponse(_ message: String)
    {
        
        if message.caseInsensitiveCompare(AudioPlayerInternalEvents.bufferingstart.rawValue) == ComparisonResult.orderedSame
        {
            self.playerDelegate?.onBufferingStart?()
        }
        else if message.caseInsensitiveCompare(AudioPlayerInternalEvents.bufferingcomplete.rawValue) == ComparisonResult.orderedSame
        {
            self.playerDelegate?.onBufferingComplete?()
        }
        else if message.contains(AudioPlayerInternalEvents.bufferingprogress.rawValue)
        {
            //Aseem - Needs to be done
            if let index = message.lowercased().characters.index(of: ":")
            {
                //let val = message.substring(with: (<#T##String.CharacterView corresponding to `index`##String.CharacterView#>.index(index, offsetBy: 1) ..< message.endIndex))
                let val = message.substring(with: (message.lowercased().characters.index(index, offsetBy: 1) ..< message.endIndex))
                self.playerDelegate?.onBufferingProgress?(Int(val)!)
            }
        }
        else if message.contains(AudioPlayerInternalEvents.currentplaytime.rawValue)
        {
            //Aseem - Needs to be done
            if let index = message.lowercased().characters.index(of: ":")
            {
                let val = message.substring(with: (message.lowercased().characters.index(index, offsetBy: 1) ..< message.endIndex))
                self.playerDelegate?.onCurrentPlayTime?(Int(val)!)
            }
        }
        else if message.contains(AudioPlayerInternalEvents.streamcompleted.rawValue)
        {
            self.playerDelegate?.onStreamCompleted?()
        }
        else if message.contains(AudioPlayerInternalEvents.totalduration.rawValue)
        {
            //Aseem - Needs to be done
            if let index = message.lowercased().characters.index(of: ":")
            {
                let val = message.substring(with: (message.lowercased().characters.index(index, offsetBy: 1) ..< message.endIndex))
                self.playerDelegate?.onStreamingStarted?(Int(val)!)
            }
        }
        
    }
    
    /**
       This method handle player queue event.
     
     - parameter message: contain events like add,remove and clear list.
    */
    fileprivate func handlePlayerQueueEventResponse(_ message: [String:AnyObject])
    {
        var resp = message
        
        let event = resp[MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue] as! String
        
        resp.removeValue(forKey: MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue)
        
        if event == PlayerQueueSubEvents.enqueue.rawValue
        {
            self.playerDelegate?.onAddToList?(resp)
        }
        else if event == PlayerQueueSubEvents.dequeue.rawValue
        {
            self.playerDelegate?.onRemoveFromList?(resp)
        }
        else if event == PlayerQueueSubEvents.clear.rawValue
        {
            self.playerDelegate?.onClearList?()
        }
        else if event == PlayerQueueSubEvents.fetch.rawValue && (resp[MediaPlayer.PlayerProperty.PLAYER_DATA.rawValue] != nil)
        {
            //Aseem -> Need to check what to return: Array or Dictionary
            self.playerDelegate?.onGetList?(resp)
        }
    }
    
    /**
       This method handle player controlevents like mute/unmute
     
     - parameter message: contain events like mute/unmute
    */
    fileprivate func handleExtraResponse(_ message: String)
    {
        if message.contains(PlayerControlEvents.mute.rawValue)
        {
            self.playerDelegate?.onMute?()
        }
        else if message.contains(PlayerControlEvents.unMute.rawValue)
        {
            self.playerDelegate?.onUnMute?()
        }
        else if message.contains(BasePlayer.PlayerControlEvents.getVolume.rawValue)
        {
            Log.debug("message is \(message)")
            if let index = message.lowercased().characters.index(of: ":")
            {
                let val = message.substring(with: (message.lowercased().characters.index(index, offsetBy: 1) ..< message.endIndex))
                self.playerDelegate?.onVolumeChange?(Int(val)!)
            }
        }
    }


}


