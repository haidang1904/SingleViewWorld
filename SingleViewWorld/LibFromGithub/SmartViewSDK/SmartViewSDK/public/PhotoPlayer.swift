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

/// The Photo Player delegate protocol defines the event methods available for a Photo.
@objc public protocol PhotoPlayerDelegate: class
{
    
//MARK: All Optional Callbacks
    /**
      event occurs when Photo is shared with TV for the first time or after audio/video share.
    */
    @objc optional func onPlayerInitialized()
    /**
     event occurs when different type of media is shared with TV.
     (Photo is shared after audio/video share)
     
     - parameter playerType: current player type (photo/audio/video)
     */
    @objc optional func onPlayerChange(_ playerType: String)
    
    /**
      event occurs when paused photo player list is played.
    */
    @objc optional func onPlay()
    /**
      event occurs on photo player list pause.
    */
    @objc optional func onPause()
    /**
     event occurs on photo player list stop.
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
    @objc optional func onControlStatus(_ volLevel: Int, muteStatus: Bool)
    /**
       event occurs on  player volume change.
     
     - parameter volLevel: player volume to be set.
     */
    @objc optional func onVolumeChange(_ volLevel: Int)
    
    /**
       event occurs on photo(image) addition in TV queue(player list).
     
     - parameter enqueuedItem:  enqueued photo item.
    */
    @objc optional func onAddToList(_ enqueuedItem: [String: AnyObject])
    /**
       event occurs on photo remove from TV queue(player list).
     
     - parameter dequeuedItem: dequeued photo item.
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
       occurs when new photo is shared with TV.
     
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

/// Photo Player Class handle the Photo share,control and TV Player queue.
@objc open class PhotoPlayer: BasePlayer
{
    /// The Photo Player delegate protocol defines the event methods available for a Photo.
    open weak var playerDelegate: PhotoPlayerDelegate? = nil
    fileprivate var additionalData = [String: AnyObject]()
    
    /**
       photo Player Attributes
     
     - title:      title
     */
    fileprivate enum PhotoPlayerAttributes: String
    {
        case title                          = "title"
    }
    
    /**
     Photo Player state
     
     - streamcompleted:   stream completed
     - currentplaytime:   current play time
     - totalduration:     total duration
     - bufferingstart:    buffering start
     - bufferingprogress: buffering progress
     - bufferingcomplete: buffering complete
     */
    fileprivate enum PhotoPlayerInternalEvents: String
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
        case PLAYER_INTERNAL_RESPONSE                     = "Photo State"
        case PLAYER_QUEUE_EVENT_RESPONSE                  = "queue"
    }
    
    /**
       Initialize photo player object
     
     - parameter mediaplayer: photo player
     */
    internal override init(mediaplayer: MediaPlayer)
    {
        super.init(mediaplayer: mediaplayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PhotoPlayer.onMessage(_:)), name: NSNotification.Name(rawValue: MediaPlayer.PlayerNotification.onMessage.rawValue), object: nil)
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
      this method play image content on TV.
    
    - parameter contentURL:        image Url
    - parameter completionHandler: The response completion closure, it will be executed in the request queue i.e. in a backgound thread.
    */
    @objc open func playContent(_ contentURL: URL, completionHandler: ((NSError?) -> Void)? = nil)
    {
        playContent(contentURL, title: "", completionHandler: completionHandler)
    }
    
    /**
       this method play image content on TV.
     
     - parameter contentURL:        image URL
     - parameter title:             image Title
     - parameter completionHandler: The response completion closure, it will be executed in the request queue i.e. in a backgound thread.
     */
    @objc open func playContent(_ contentURL: URL?, title: String, completionHandler: ((NSError?) -> Void)? = nil)
    {
        
        let json:[String: AnyObject]
        if  let URL_content = contentURL
        {
            json = [
                MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : URL_content.absoluteString as AnyObject,
                PhotoPlayerAttributes.title.rawValue : title as AnyObject
            ]
        }
        else
        {
            json = [
                MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : "" as AnyObject,
                PhotoPlayerAttributes.title.rawValue : title as AnyObject
            ]
        }
        additionalData = json
        
        mPlayer.playContent(json, type: PlayerTypes.PHOTO, completionHandler: completionHandler)
        
    }
    
    //Video Player Controls
    /**
       sets slide show timeout period
     
     - parameter time: slide show time-out period in milliseconds.
    */
    @objc open func setSlideTimeout(_ time: TimeInterval)
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: (PlayerControlEvents.slideTimeout.rawValue + ":" + String(Int(time))) as AnyObject?)
    }
    
    /**
       sets background audio in slide show.
 
     - parameter contentURL: Background audio contentURL.
    */
    @objc open func setBackgroundMusic(_ contentURL: URL)
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: (PlayerControlEvents.playMusic.rawValue + ":" + contentURL.absoluteString) as AnyObject?)
    }
    
    /**
      stops background audio in slide show.
    */
    @objc open func stopBackgroundMusic()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.stopMusic.rawValue as AnyObject?)
    }
    
    /**
       resumes TV widget/application from background process.
     */
    @objc open func resumeApplicationInForeground(_ completionHandler: ((NSError?) -> Void)? = nil)
    {
        mPlayer.sendStartDMPApplication(PlayerTypes.PHOTO, completionHandler: completionHandler)
    }
    
    /**
     request player list i.e currently playing on TV.
     */
    @objc open func getList()
    {
        let json:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue : PlayerQueueSubEvents.fetch.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.PHOTO.rawValue as AnyObject
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
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.PHOTO.rawValue as AnyObject
        ]
        
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_QUEUE_EVENT, data: json as AnyObject?)
    }
    
    /**
       remove specific image from player list.
     
     - parameter contentURL: image URL
     */
    @objc open func removeFromList(_ contentURL: URL)
    {
        let json:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.PLAYER_SUB_EVENT.rawValue : PlayerQueueSubEvents.dequeue.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.PHOTO.rawValue as AnyObject,
            MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : contentURL.absoluteString as AnyObject
        ]
        
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_QUEUE_EVENT, data: json as AnyObject?)
    }
    
    /**
       add image to player list.
     
     - parameter contentURL:   URL
     - parameter title:        Title
     - parameter albumName:    Album NAme
     - parameter albumArtUrl:  Album Art URL
    */
    @objc open func addToList(_ contentURL: URL, title: String = "", albumName: String = "", albumArtUrl: URL = URL(fileURLWithPath: ""))
    {
        let dict:[String: AnyObject] = [
            MediaPlayer.PlayerProperty.CONTENT_URI.rawValue : contentURL.absoluteString as AnyObject,
            PhotoPlayerAttributes.title.rawValue : title as AnyObject
        ]
        
        addToList([dict])
    }
    
    /**
       add Photo item to player list.
     
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
            
            if (data[PhotoPlayerAttributes.title.rawValue] != nil)
            {
                title = data[PhotoPlayerAttributes.title.rawValue] as? String
            }
            
            
            playContent(contentURL, title: title!, completionHandler:
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
            MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue : PlayerTypes.PHOTO.rawValue as AnyObject
        ]
        
        if let contentUrlStr = dataDict[MediaPlayer.PlayerProperty.CONTENT_URI.rawValue]
        {
            json.updateValue(contentUrlStr as! String as AnyObject, forKey: MediaPlayer.PlayerProperty.CONTENT_URI.rawValue)
        }
        else
        {
            return nil
        }
        
        if let title = dataDict[PhotoPlayerAttributes.title.rawValue]
        {
            json.updateValue(title as! String as AnyObject, forKey: PhotoPlayerAttributes.title.rawValue)
        }

        return json
    }
    
    /**
        parsing the data
     
     - parameter data: parsing data to events
    */
    fileprivate func parseData(_ data: [String : AnyObject])
    {        
        if (mPlayer.playerContentType != PlayerTypes.PHOTO.rawValue)
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
                additionalData.updateValue(PlayerTypes.PHOTO.rawValue as AnyObject, forKey: MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue)
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
                
                self.playerDelegate?.onPlayerChange?(PlayerTypes.PHOTO.rawValue)
            }
        }
        else if (data[MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue] != nil) &&
           // let playerType = data[MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue] as! String &&
            (data[MediaPlayer.PlayerProperty.PLAYER_TYPE.rawValue] as! String).caseInsensitiveCompare(PlayerTypes.PHOTO.rawValue) == ComparisonResult.orderedSame
        {
            //Handle other events..
            if let play_cont_resp = data[PlayerTags.PLAYER_CONTROL_RESPONSE.rawValue]
            {
                handlePlayerControlResponse(play_cont_resp as! String)
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
                        
                        self.playerDelegate?.onControlStatus?(volumeLevel, muteStatus: muteStatus)
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
    func handlePlayerControlResponse(_ message: String)
    {
        if message.contains(PlayerControlEvents.play.rawValue)
        {
            self.playerDelegate?.onPlay?()
        }
        else if message.contains(PlayerControlEvents.pause.rawValue)
        {
            self.playerDelegate?.onPause?()
        }
        else if message.contains(PlayerControlEvents.stop.rawValue)
        {
            self.playerDelegate?.onStop?()
        }
        else if message.contains(PlayerControlEvents.next.rawValue)
        {
            self.playerDelegate?.onNext?()
        }
        else if message.contains(PlayerControlEvents.previous.rawValue)
        {
            self.playerDelegate?.onPrevious?()
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




