//----------------------------------------------------------------------------------------------------
// Event for SoundLoader
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.utils {
    import flash.events.*;
    
    
    /** SoundLoader Event class. */
    public class SoundLoaderEvent extends Event 
    {
    // constants
    //------------------------------------------------------------
        /** Dispatch when complete all file loadings, this event is dispatched whether errors appear.
         * @eventType completeAll
         */
        static public const COMPLETE_ALL:String = 'completeAll';
        
        
        /** Dispatch when complete one file loading.
         * @eventType complete
         */
        static public const COMPLETE:String = 'complete';
        
        
        /** Dispatch when file read error appears
         *  @eventType soundLoaderError
         */
        static public const ERROR:String = 'soundLoaderError';
        
        
        
        
    // valiables
    //----------------------------------------
        /** sound loader @private */
        protected var _soundLoader:SoundLoader;
        
        /** file data @private */
        protected var _fileData:SoundLoaderFileData;
        
        
        
        
    // properties
    //----------------------------------------
        /** Sound loader instance. */
        public function get soundLoader():SoundLoader { return _soundLoader; }
        
        /** file data. */
        public function get fileData():SoundLoaderFileData { return _fileData; }
        
        /** loaded data. */
        public function get data():* { return _fileData.data; }
        
        
        
        
    // functions
    //----------------------------------------
        /** Creates an SoundLoaderEvent object to pass to event listeners as an argument. */
        public function SoundLoaderEvent(type:String, soundLoader:SoundLoader, fileData:SoundLoaderFileData)
        {
            super(type, false, false);
            _soundLoader = soundLoader;
            _fileData = fileData;
        }
        
        
        /** clone. */
        override public function clone() : Event
        { 
            return new SoundLoaderEvent(type, _soundLoader, _fileData);
        }
    }
}

