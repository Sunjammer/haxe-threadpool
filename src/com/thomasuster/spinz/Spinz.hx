package com.thomasuster.spinz;

#if cpp
import cpp.vm.Mutex;
import cpp.vm.Thread;
#else
import neko.vm.Mutex;
import neko.vm.Thread;
#end

typedef Task = Void->Void;

class Spinz {

    var num:Int;
    var theEnd:Bool;
    var numAlive:Int;
    var numAliveM:Mutex;
    
    var models:Array<ThreadModel>;
    
    var queue:Array<Task>;

    public function new(num:Int):Void {
        this.num = num;
        numAlive = num;
        models = [];
        queue = [];
        numAliveM = new Mutex();

        for (i in 0...num) {
            var model = new ThreadModel();
            model.mutex.acquire();
            models.push(model);
        }

        for (i in 0...num) {
            Thread.create(function() {
                threadLoop(models[i]);
            });
        }
    }

    function threadLoop(model:ThreadModel):Void {
        while(true) {
            if(theEnd)
                break;
            model.mutex.acquire();
            if(!model.done) {
                for (i in model.start...model.end)
                    queue[i]();
                model.done = true;   
            }
            model.mutex.release();
        }
        numAliveM.acquire();
        numAlive--;
        numAliveM.release();
    }

    public function addConcurrent(task:Task):Void {
        queue.push(task);
    }

    public function runAll():Void {
        var numPerThread:Int = Math.floor(queue.length / num);
        var remainder:Int = queue.length - num * numPerThread;
        for (i in 0...num) {
            models[i].start = i*numPerThread;
            models[i].end = models[i].start + numPerThread;
            if(i == num-1) {
                models[i].end += remainder;
            }
            models[i].mutex.release();
        }

        for (i in 0...num) {
            models[i].mutex.acquire();
        }
        queue = [];
    }

    public function end():Void {
        theEnd = true;
        for (i in 0...num) {
            models[i].mutex.release();
        }
    }

}