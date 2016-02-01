# WEBlueToothManager

一个关于蓝牙4.0的智能硬件Demo详解

>  写这篇详解是因为最近很多人都在问相关问题，但是上篇文章[iOS-BLE蓝牙开发持续更新](http://blog.yuhanle.com/2015/08/24/ble-development-continuously-update/)已经过去半年，很多东西已经开始遗忘，今天重新拾起，并在Demo中新添了具体功能和详细注释，顺便屡一下当初设计的思路，我想用图片来解释会更好理解。

  首先看一下几个文件的大概功能，后面在用图来分析其中的设计理念。
#### 文件目录
  整个文件主要包含四大块，每一块的功能都是独立开的，不过当中却又设计不足的地方，希望各位能够积极fork，贡献代码！

- QWSDiscovery

  这个文件是功能的核心，主要负责和系统的CoreBluetooth沟通，比如扫描设备，连接，断开等操作。其中维护了一个设备列表，使用设备的uuid来唯一识别。在这个文件中，同时也定义了通知和错误类型，方便处理与设备之间的信息交流。


- QWSBleHelper 

  用心的读者一定发现，在我们的每一个viewController中，只要与蓝牙功能相关，那他一定维护了一个helper。在这里我称这个页面为监护人，智能设备就像是一个孩子，很多孩子在幼儿园里，我只关心我的孩子，而这个helper就像幼儿园老师，他负责告知我们孩子在校的情况，也可以让我和孩子直接沟通。

  helper中会维护两个集合，一个是我关心的设备集合，一个是即将断开的设备集合。并不是连接成功的设备就会加入到这个集合中，只有监护人发出了与这个设备相关的请求（比如说，连接，获取信息等），这个时候，hepler可以判定这个设备是被监护人关心的，从而这个设备有信息更新的时候，他会告知所有监护这个设备的监护人。

  在这里之所以即将断开的设备集合是为了，在监护人发出断开请求之后，仍然能够清晰的告知监护人该设备的状态信息，等到真正断开连接之后通知到每一个监护人。

- QWSBleHandler

  这个文件顾名思义，就是一些代理方法。设计中是将他加入到helper中，当helper收到设备发来的信息时，通过代理将信息拆解并封装模型通知到所有监护人，写在这里纯粹只是为了看起来更加清晰，分担一下各个文件的代码压力。

- QWSDevControlService

  继承NSObject，封装的智能硬件设备的模型。
对于智能硬件设备来讲，单单一个CBPeripheral（CoreBluetooth里的对象）是远远不够的。我们可能需要为他丰富更多的扩展信息，比如这个设备是否自动重连，是否需要断开后连接，是否认证，重连次数，版本号等，当然也可以继承CBPeripheral，但这里我觉得将CBPeripheral作为其一个属性会比较清晰。

  这个对象会维护自己所有的读写操作，不管外界发来什么指令信息，他都能根据自己当前的状态，该报错报错，该执行执行，并将结果反馈给每一个监护人。

***

#### 图解说明

  1.智能设备与移动端的关系

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/545755-487c20b56ddab822.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

 我们的Discovery在最顶层，不会参与与设备的直接交互，所有的收发数据都是经过系统的框架实现。

  2.监护人与孩子的关系

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/545755-01aabb5e39a0a750.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

  图中的连线很多，可能很迷糊，同一种颜色的连线代表数据交互，看helper里关心的设备，可以明显理解，只有关心这个设备才会收到这个设备的信息。
  
  每一个viewController维护一个helper，通过NSNotificationCenter广播所有操作的结果，并告知每一个关心这个设备的viewController。
  
  简言之，就是监护人接不接受这个通知，或者老师发不发送这个消息给监护人。有一点需要明白的是，不管监护人想不想收到这个设备的消息，这个设备都是会广播自己的信息的，只是helper会判断这个孩子是不是你的~

  以上就是这个Demo的设计思路，当然Demo中仍有很多不足，之所以不敢称之为kit，是因为它确实没有达到kit的封装能力与效果，毕竟这只是一个Demo，他只是简单体现了一个设计思路，并不能达到通用的效果，因为在智能硬件这一块，每个产品的协议，属性都会有所差异，不可能做到通用的效果。希望和大家有更深入的交流与学习！

  最后回顾一下上篇文章的地址：[iOS-BLE蓝牙开发持续更新](http://blog.yuhanle.com/2015/08/24/ble-development-continuously-update/)
  
  以及这个说了很久的Demo地址：[一个iOS BLE蓝牙学习的Demo](https://github.com/yuhanle/WEBlueToothManager)


###ps：
  在这里也顺便介绍一下近期看到的一篇关于BLE开发的kit([MPBluetoothKit iOS蓝牙框架](http://macpu.github.io/2015/11/04/MPBluetoothKit-iOS%E8%93%9D%E7%89%99%E6%A1%86%E6%9E%B6/))，作者很详细的将系统的CoreBluetooth的代理都用block实现了，看起来更加清晰与实用，也希望各位能够多多关注，共同学习。

