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

//MARK: VideoPlayerDelegate
/// The Video Player delegate protocol defines the event methods available for a Video.
@objc public protocol VideoPlayerDelegate: class
{

    //MARK: All Optional Callbacks
    /**
      event occurs on Buffering of Video Start.
    */
    @objc optional func onBufferingStart()
    /**
     event occurs on Buffering of Video Complete.
    */
    @objc optional func onBufferingComplete()
    /**
       event occurs asynchronously when video buffering is in progress.
     
     - parameter progress: current Buffer Progerss
     */
    @objc optional func onBufferingProgress(_ progress: Int)
    /**
       event occurs continously when video streaming is going on.
     
     - parameter progress: current playing time of video.
     */
    @objc optional func onCurrentPlayTime(_ progress: Int)
    /**
       event occurs when video streaming start.
     
     - parameter duration: total duration of video.
    */
    @objc optional func onStreamingStarted(_ duration: Int)
    /**
      event occurs when video streaming completed.
    */
    @objc optional func onStreamCompleted()
    /**
      event occurs when video is shared with TV for the first time.
    */
    @objc optional func onPlayerInitialized()
    /**
       event occurs when different type of media is shared with TV.
       (video is shared after photo/audio share)
     
     - parameter playerType: current player type (photo/audio/video)
     */
    @objc optional func onPlayerChange(_ playerType: String)
    
    /**
      event occurs when paused video is played.
    */
    @objc optional func onPlay()
    /**
      event occurs on video pause.
    */
    @objc optional func onPause()
    /**
      event occurs on video stop.
    */
    @objc optional func onStop()
    /**
      event occurs on fast forwarding the video.
    */
    @objc optional func onForward()
    /**
      event occurs on rewind the video.
    */
    @objc optional func onRewind()
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
    @objc optional func onControlStatus(_ volLevel: Int, muteStatus: Bool, mode: String)
    /**
       event occurs on  player volume change.
     
     - parameter volLevel: player volume to be set.
    */
    @objc optional func onVolumeChange(_ volLevel: Int)
    
    /**
       event occurs on video addition in TV queue(player list).
     
     - parameter enqueuedItem:  enqueued video item.
    */
    @objc optional func onAddToList(_ enqueuedItem: [String: AnyObject])
    /**
       event occurs on video remove from TV queue(player list).
     
     - parameter dequeuedItem: dequeued video Item.
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
    //optional func onShuffle(status: Bool)
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

/// Video Player Class handle the Video share, control and TV Player queue.
@objc open class VideoPlayer: BasePlayer
{
    /// The Video Player delegate protocol defines the event methods available for a Video.
    open weak var playerDelegate: VideoPlayerDelegate? = nil
    fileprivate var additionalData = [String: AnyObject]()
    
    fileprivate enum VideoPlayerAttributes: String
    {
        case title                          = "title"
        case thumbnailUrl                   = "thumbnailUrl"
    }
    
    fileprivate enum VideoPlayerInternalEvents: String
    {
        case streamcompleted                = "streamcompleted"
        case currentplaytime                = "currentplaytime"
        case totalduration                  = "totalduration"
        case bufferingstart                 = "bufferingstart"
        case bufferingprogress              = "bufferingprogress"
        case bufferingcomplete              = "bufferingcomplete"
    }
    
    internal enum PlayerTags: String
    {
        case PLAYER_CONTROL_RESPONSE                      = "state"
        case PLAYER_INTERNAL_RESPONSE                     = "Video State"
        case PLAYER_QUEUE_EVENT_RESPONSE                  = "queue"
    }
    
    /**
       Initialize video player object
     
     - parameter mediaplayer: video player
     */
    internal override init(mediaplayer: MediaPlayer)
    {
        super.init(mediaplayer: mediaplayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayer.onMessage(_:)), name: NSNotification.Name(rawValue: MediaPlayer.PlayerNotification.onMessage.rawValue), object: nil)
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
      this method play video content on TV.
    
    - parameter contentURL:        video Url
    - parameter completionHandler: The response completion closure, it will be executed in the request queue i.e. in a backgound thread.
    */
    @objc open func playContent(_ contentURL: URL, completionHandler: ((NSError?) -> Void)? = nil)
    {
        playContent(contentURL, title: "", thumbnailURL: URL(fileURLWithPath: ""), completionHandler: completionHandler)
    }
    /**
       this method play video content on TV.

     - parameter contentURL:        Content URL
     - parameter title:             Content Title
     - parameter thumbnailURL:      Content thumbnail URL
     - parameter completionHandler: The response completion closure, it will be executed in the request queue i.e. in a backgound thread.
     */
    
    @objc open func playContent(_ contentURL: URL?, title: String, thumbnailURL: URL?, completionHandler: ((NSError?) -> Void)? = nil)
    {
        
        let json:[String: AnyObject]
        if let URL_thumbnail = thumbnailURL , let URL_content = contentURL
        {
            json = [
                MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : URL_content.absoluteString as AnyObject,
                VideoPlayerAttributes.title.rawValue : title as AnyObject,
                VideoPlayerAttributes.thumbnailUrl.rawValue : URL_thumbnail.absoluteString as AnyObject
            ]
        }
        else if let URL_content = contentURL
        {
            json = [
                MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : URL_content.absoluteString as AnyObject,
                VideoPlayerAttributes.title.rawValue : title as AnyObject,
                VideoPlayerAttributes.thumbnailUrl.rawValue : "" as AnyObject
                
            ]
        }
        else if let URL_thumbnail = thumbnailURL
        {
            json = [
                MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : "" as AnyObject,
                VideoPlayerAttributes.title.rawValue : title as AnyObject,
                VideoPlayerAttributes.thumbnailUrl.rawValue : URL_thumbnail.absoluteString as AnyObject
            ]
        }
        else
        {
            json = [
                MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : "" as AnyObject,
                VideoPlayerAttributes.title.rawValue : title as AnyObject,
                VideoPlayerAttributes.thumbnailUrl.rawValue : "" as AnyObject
            ]
        }
        additionalData = json
        
        mPlayer.playContent(json, type: PlayerTypes.VIDEO, completionHandler: completionHandler)
        
    }
    
    //Video Player Controls
    /**
       This method sends request to player for fast forwarding the video.
    */
    @objc open func forward()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.FF.rawValue as AnyObject?)
    }
    /**
       This method sends request to player for rewind the video.
    */
    @objc open func rewind()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.RWD.rawValue as AnyObject?)
    }
    
    /**
       Seek the given time in currently playing media.
     
     - parameter time: Time in seconds within length of currently playing media.
    */
    @objc open func seek(_ time: TimeInterval)
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: "seekTo:\(Int(time))" as AnyObject?)
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
       resumes TV widget/application from background process.
     
     - parameter completionHandler: The response completion closure, it will be executed in the request queue i.e. in a backgound thread.
     */
    @objc open func resumeApplicationInForeground(_ completionHandler: ((NSError?) -> Void)? = nil)
    {
        mPlayer.sendStartDMPApplication(PlayerTypes.VIDEO, completionHandler: completionHandler)
    }
    
//    @objc public func shuffle()
//    {
//        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.shuffle.rawValue)
//    }
    
    /**
       request player list i.e currently playing on TV.
    */
    @objc open func getList()
    {
        let json:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue : PlayerQueueSubEvents.fetch.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.VIDEO.rawValue as AnyObject
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
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.VIDEO.rawValue as AnyObject
        ]
        
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_QUEUE_EVENT, data: json as AnyObject?)
    }
    
    /**
       remove specific video content from player list.
     
     - parameter contentURL: video URL
    */
    @objc open func removeFromList(_ contentURL: URL)
    {
        let json:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue : PlayerQueueSubEvents.dequeue.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.VIDEO.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : contentURL.absoluteString as AnyObject
        ]
        
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_QUEUE_EVENT, data: json as AnyObject?)
    }
    
    /**
       Add video item to player list.
     
     - parameter contentURL:   URL
     - parameter title:        Title
     - parameter thumbnailURL: thumbnail URL
    */
    @objc open func addToList(_ contentURL: URL, title: String = "", thumbnailURL: URL = URL(fileURLWithPath: ""))
    {
        let dict:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : contentURL.absoluteString as AnyObject,
            VideoPlayerAttributes.title.rawValue : title as AnyObject,
            VideoPlayerAttributes.thumbnailUrl.rawValue : thumbnailURL.absoluteString as AnyObject
            
        ]
        
        addToList([dict])
    }
    
    /**
        Add video item to player list.
     
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
            
           Log.debug("content URL test2")
            
            if (data[VideoPlayerAttributes.title.rawValue] != nil)
            {
                title = data[VideoPlayerAttributes.title.rawValue] as? String
            }
            
            if let thumbURLStr = data[VideoPlayerAttributes.thumbnailUrl.rawValue]
            {
                thumbURL = URL(fileURLWithPath: thumbURLStr as! String)
            }
            
            
            playContent(contentURL, title: title!, thumbnailURL: thumbURL!, completionHandler:
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
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.VIDEO.rawValue as AnyObject
            ]
        
        if let contentUrlStr = dataDict[MediaPlayer.PlayerProperty.CONTENT_URI.rawValue]
        {
            json.updateValue(contentUrlStr as! String as AnyObject, forKey: MediaPlayer.PlayerProperty.CONTENT_URI.rawValue)
        }
        else
        {
            return nil
        }
        
        if let title = dataDict[VideoPlayerAttributes.title.rawValue]
        {
            json.updateValue(title as! String as AnyObject, forKey: VideoPlayerAttributes.title.rawValue)
        }
        
        if let thumbURLStr = dataDict[VideoPlayerAttributes.thumbnailUrl.rawValue]
        {
            json.updateValue(thumbURLStr as! String as AnyObject, forKey: VideoPlayerAttributes.thumbnailUrl.rawValue)
        }
        
        return json
        

    }
    
    /**
     parsing the data
     
     - parameter data: parsing data to events
     */
    fileprivate func parseData(_ data: [String : AnyObject])
    {
        if (mPlayer.playerContentType != PlayerTypes.VIDEO.rawValue)
        {
            return;
        }
        
        if let errorStr = data[MediaPlayer.PlayerProperty.PLAYER_ERROR_MESSAGE_EVENT.rawValue]
        {
            //call onError -> Error code can be Integer or Message
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
                additionalData.updateValue(PlayerTypes.VIDEO.rawValue as AnyObject, forKey: MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue)
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
                
                self.playerDelegate?.onPlayerChange?(PlayerTypes.VIDEO.rawValue)
            }
        }
        else if (data[MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue] != nil) &&
           // let playerType = data[MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue] as! String &&
            (data[MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue] as! String).caseInsensitiveCompare(PlayerTypes.VIDEO.rawValue) == ComparisonResult.orderedSame
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
                        //var shuffleStatus = false
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
//                        if let controlShuffle = data[PlayerControlStatus.shuffle.rawValue]
//                        {
//                            if (controlShuffle is Bool && controlShuffle as! Bool == true)
//                            {
//                                shuffleStatus = true
//                            }
//                        }
                        if let controlRepeat = data[PlayerControlStatus.`repeat`.rawValue]
                        {
                            if (controlRepeat as! String).contains(RepeatMode.repeatAll.rawValue)
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
                        
                        self.playerDelegate?.onControlStatus?(volumeLevel, muteStatus: muteStatus, /*shuffleStatus: shuffleStatus,*/ mode: repeatMode)
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
            else if mess.contains(PlayerControlEvents.FF.rawValue)
            {
                self.playerDelegate?.onForward?()
            }
            else if mess.contains(PlayerControlEvents.RWD.rawValue)
            {
                self.playerDelegate?.onRewind?()
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
//            else if let value = messageDict[PlayerControlEvents.shuffle.rawValue]
//            {
//                if value as! Bool
//                {
//                    self.playerDelegate?.onShuffle?(true)
//                }
//                else
//                {
//                    self.playerDelegate?.onShuffle?(false)
//                }
//            }
        }
        
    }
    
    /**
     handle response to event
     
     - parameter message: response contains player state like buffering and streaming state
     */
    fileprivate func handlePlayerInternalResponse(_ message: String)
    {
        
        if message.caseInsensitiveCompare(VideoPlayerInternalEvents.bufferingstart.rawValue) == ComparisonResult.orderedSame
        {
            self.playerDelegate?.onBufferingStart?()
        }
        else if message.caseInsensitiveCompare(VideoPlayerInternalEvents.bufferingcomplete.rawValue) == ComparisonResult.orderedSame
        {
            self.playerDelegate?.onBufferingComplete?()
        }
        else if message.contains(VideoPlayerInternalEvents.bufferingprogress.rawValue)
        {
            //Aseem TODO: - Needs to be done
            if let index = message.lowercased().characters.index(of: ":")
            {
                let val = message.substring(with: (message.lowercased().characters.index(index, offsetBy: 1) ..< message.endIndex))
                self.playerDelegate?.onBufferingProgress?(Int(val)!)
            }
        }
        else if message.contains(VideoPlayerInternalEvents.currentplaytime.rawValue)
        {
            //Aseem - Needs to be done
            if let index = message.lowercased().characters.index(of: ":")
            {
                let val = message.substring(with: (message.lowercased().characters.index(index, offsetBy: 1) ..< message.endIndex))
                self.playerDelegate?.onCurrentPlayTime?(Int(val)!)
            }
        }
        else if message.contains(VideoPlayerInternalEvents.streamcompleted.rawValue)
        {
            self.playerDelegate?.onStreamCompleted?()
        }
        else if message.contains(VideoPlayerInternalEvents.totalduration.rawValue)
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
            //Aseem TODO: Check volume in the json
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


