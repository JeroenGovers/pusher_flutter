package nl.jeroengovers.pusher

import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import com.pusher.client.Pusher
import com.pusher.client.PusherOptions
import com.pusher.client.connection.ConnectionEventListener
import com.pusher.client.connection.ConnectionState
import com.pusher.client.connection.ConnectionStateChange
import com.pusher.client.channel.ChannelEventListener
import com.pusher.client.channel.PrivateChannelEventListener
import com.pusher.client.util.HttpAuthorizer
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.lang.Exception

class PusherPlugin : MethodCallHandler, ConnectionEventListener {
    var pusher: Pusher? = null
    val eventStreamHandler = MessageStreamHandler()

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val instance = PusherPlugin()
            val channel = MethodChannel(registrar.messenger(), "flutter.jeroengovers.nl/pusher")
            channel.setMethodCallHandler(instance)

            val messageEventChannel = EventChannel(registrar.messenger(), "flutter.jeroengovers.nl/pusher/event")
            messageEventChannel.setStreamHandler(instance.eventStreamHandler)
        }
    }

    override fun onConnectionStateChange(change: ConnectionStateChange) {
        var socketId: String = ""

        if (change.currentState == ConnectionState.CONNECTED) {
            socketId = pusher?.getConnection()?.socketId.toString();
        }

        eventStreamHandler.send("_connection",
                "state",
                "change",
                JSONObject(mapOf(
                        "socketId" to socketId,
                        "state" to change.currentState.toString().toLowerCase())).toString()
        )
    }

    override fun onError(message: String?, code: String?, e: Exception?) {
        e?.printStackTrace()
        val errMessage = message ?: e?.localizedMessage ?: "Unknown error"

        eventStreamHandler.send("_connection", "error", "error", JSONObject(mapOf("code" to code, "message" to errMessage)).toString())
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "create" -> {
                val apiKey = call.argument<String>("apiKey")

                val pusherOptions = PusherOptions()
                val cluster = call.argument<String?>("cluster")
                if (cluster != null) {
                    pusherOptions.setCluster(cluster)
                }

                val host = call.argument<String?>("host")
                if (host != null) {
                    pusherOptions.setHost(host)
                }

                var encrypted = call.argument<Boolean?>("encrypted")
                if (encrypted == null) {
                    encrypted = true
                }

                pusherOptions.isEncrypted = encrypted

                val port = call.argument<Int?>("port")
                if (port != null) {
                    if (encrypted == true) {
                        pusherOptions.setWssPort(port)
                    } else {
                        pusherOptions.setWsPort(port)
                    }
                }

                val activityTimeout = call.argument<Long?>("activity_timeout")
                if (activityTimeout != null) {
                    pusherOptions.activityTimeout = activityTimeout
                }

                val pongTimeout = call.argument<Long?>("pong_timeout")
                if (pongTimeout != null) {
                    pusherOptions.pongTimeout = pongTimeout
                }

                val maxReconnectionAttempts = call.argument<Int?>("max_reconnection_attempts")
                if (maxReconnectionAttempts != null) {
                    pusherOptions.maxReconnectionAttempts = maxReconnectionAttempts
                }

                val maxReconnectGapInSeconds = call.argument<Int?>("max_reconnect_gap_in_seconds")
                if (maxReconnectGapInSeconds != null) {
                    pusherOptions.maxReconnectGapInSeconds = maxReconnectGapInSeconds
                }

                val authorizer = call.argument<String?>("authorizer")
                if (authorizer != null) {
                    pusherOptions.authorizer = HttpAuthorizer(authorizer)
                }

                pusher = Pusher(apiKey, pusherOptions)

                result.success(null)
            }
            "connect" -> {
                pusher?.connect(this, ConnectionState.ALL)

                result.success(null)
            }
            "disconnect" -> {
                pusher?.disconnect()
                pusher = null

                result.success(null)
            }
            "subscribe" -> {
                val pusher = this.pusher ?: return
                val event = call.argument<String>("event")
                        ?: throw RuntimeException("Must provide event name")
                val channelName = call.argument<String>("channel")
                        ?: throw RuntimeException("Must provide channel")
                var channel = pusher.getChannel(channelName)
                if (channel == null) {
                    channel = pusher.subscribe(channelName, object : ChannelEventListener {
                        override fun onSubscriptionSucceeded(channelName: String?) {
                            Log.d("subscribe", "subscription-succeeded")
                            //TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
                        }

                        override fun onEvent(channelName: String?, eventName: String?, data: String?) {
                            Log.e("subscribe", "onEvent - not used!?")
                        }
                    })
                }
                channel.bind(event) { _, eventName, data ->
                    eventStreamHandler.send(channel.name, "event", eventName, data)
                }
                result.success(null)
            }
            "subscribePrivate" -> {
                val pusher = this.pusher ?: return
                val event = call.argument<String>("event")
                        ?: throw RuntimeException("Must provide event name")
                val channelName = call.argument<String>("channel")
                        ?: throw RuntimeException("Must provide channel")

                var channel = pusher.getPrivateChannel(channelName)
                if (channel == null) {
                    channel = pusher.subscribePrivate(channelName, object : PrivateChannelEventListener {
                        override fun onAuthenticationFailure(string: String, ex: Exception) {
                            Log.d("firstSubscribePrivate", "onAuthenticationFailure")
                            Log.d("onAuthenticationFailure", string)
                            Log.d("onAuthenticationFailure", ex.toString())
                        }

                        override fun onSubscriptionSucceeded(string: String) {
                            Log.d("firstSubscribePrivate", "onSubscriptionSucceeded")
                        }

                        override fun onEvent(string: String, eventName: String, data: String) {
                            Log.d("channel-null", "onEvent-null")
                            eventStreamHandler.send(channel.name, "event", eventName, data)
                        }
                    })
                }

                channel.bind(event, object : PrivateChannelEventListener {
                    override fun onAuthenticationFailure(string: String, ex: Exception) {
                        Log.d("subscribePrivate", "onAuthenticationFailure")
                    }

                    override fun onSubscriptionSucceeded(string: String) {
                        Log.d("subscribePrivate", "onSubscriptionSucceeded")
                    }

                    override fun onEvent(string: String, eventName: String, data: String) {
                        Log.d("channel-bind", "onEvent-bind")
                        eventStreamHandler.send(channel.name, "event", eventName, data)
                    }
                })
                result.success(null)
            }
            "trigger" -> {
                val pusher = this.pusher ?: return

                val channelName = call.argument<String>("channel")
                        ?: throw RuntimeException("Must provide channel")
                val event = call.argument<String>("event")
                        ?: throw RuntimeException("Must provide event name")
                val data = call.argument<String>("data")
                        ?: throw RuntimeException("Must provide data")

                val channel = pusher.getPrivateChannel(channelName)
                channel.trigger(event, data)
            }
            else -> result.notImplemented()
        }
    }
}

class MessageStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun send(channel: String, type: String, event: String, data: String) {
        eventSink?.success(mapOf("channel" to channel,
                "type" to type,
                "event" to event,
                "body" to data))
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }
}

fun jsonToMap(json: JSONObject?): Map<String, Any> {
    var retMap: Map<String, Any> = HashMap()

    if (json != null) {
        retMap = toMap(json)
    }
    return retMap
}

fun toMap(`object`: JSONObject): Map<String, Any> {
    val map = HashMap<String, Any>()

    val keysItr = `object`.keys().iterator()
    while (keysItr.hasNext()) {
        val key = keysItr.next()
        var value = `object`.get(key)

        if (value is JSONArray) {
            value = toList(value)
        } else if (value is JSONObject) {
            value = toMap(value)
        }
        map[key] = value
    }
    return map
}

fun toList(array: JSONArray): List<Any> {
    val list = ArrayList<Any>()
    for (i in 0 until array.length()) {
        var value = array.get(i)
        if (value is JSONArray) {
            value = toList(value)
        } else if (value is JSONObject) {
            value = toMap(value)
        }
        list.add(value)
    }
    return list
}