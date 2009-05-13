//----------------------------------------------------------------------------------------------------
// Sound object
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    /** The SoundStage is to operate SiONDriver directly.
     */
    public class SoundStage extends SoundObjectContainer
    {
    // valiables
    //----------------------------------------
        
        
        
        
    // properties
    //----------------------------------------
        /** Mute. */
        override public function get mute() : Boolean { return false; }
        override public function set mute(m:Boolean) : void { 
            
        }
        
        /** Volume (0:Minimum - 1:Maximum). */
        override public function get volume() : Number { return _driver.volume; }
        override public function set volume(v:Number) : void { _driver.volume = v; }
        
        /** Panning (-1:Left - 0:Center - +1:Right). */
        override public function get pan() : Number { return _driver.pan; }
        override public function set pan(p:Number) : void { _driver.pan = p; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor. */
        function SoundStage()
        {
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Play sound. */
        override public function play() : void
        {
        }
        
        
        /** Stop sound. */
        override public function stop() : void
        {
        }
        
        
        /** Puase sound, resume by play() method. */
        override public function pause() : void
        {
        }
    }
}


