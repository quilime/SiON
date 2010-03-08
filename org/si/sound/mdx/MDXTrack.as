//----------------------------------------------------------------------------------------------------
// Track of MDX data
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.mdx {
    import flash.utils.ByteArray;
    
    
    /** Track of MDX data */
    public class MDXTrack
    {
    // variables
    //--------------------------------------------------------------------------------
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** to string. */
        public function toString():String
        {
            var text:String = "";
            return text;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function MDXTrack()
        {
            
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : MDXTrack
        {
            
            return this;
        }
        
        
        /** Load track from byteArray. */
        public function loadBytes(bytes:ByteArray) : MDXTrack
        {
            bytes.position = 0;
            clear();
            
            
            return this;
        }
    }
}


