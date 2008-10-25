//----------------------------------------------------------------------------------------------------
// SiMMLSequencerTrack Envelop table
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.driver {
    import org.si.utils.SLLint;
    
    
    public class SiMMLEnvelopTable
    {
        public var head:SLLint;
        public var tail:SLLint;
        
        function SiMMLEnvelopTable()
        {
            head = null;
            tail = null;
        }
        
        public function free() : void
        {
            if (head) {
                tail.next = null;
                SLLint.freeList(head);
                head = null;
                tail = null;
            }
        }
    }
}

