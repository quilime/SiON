//----------------------------------------------------------------------------------------------------
// PDX data class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.mdx {
    import flash.utils.ByteArray;
    
    
    /** PDX data class */
    public class PDXData
    {
    // variables
    //--------------------------------------------------------------------------------
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function PDXData()
        {
            
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : PDXData
        {
            return this;
        }
        
        
        /** Load PDX data from byteArray. */
        public function loadBytes(bytes:ByteArray) : PDXData
        {
            bytes.position = 0;
            clear();
            return this;
        }
    }
}


