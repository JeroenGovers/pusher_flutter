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
import com.pusher.client.channel.Channel
import com.pusher.client.channel.PrivateChannelEventListener
import com.pusher.client.channel.SubscriptionEventListener
import com.pusher.client.util.HttpAuthorizer
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.lang.Exception

class PusherPlugin: MethodCallHandler, ConnectionEventListener {
    var pusher: Pusher? = null
    val connectionStreamHandler = ConnectionStreamHandler()
    val messageStreamHandler = MessageStreamHandler()
    val errorStreamHandler = ErrorStreamHandler()

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val instance = PusherPlugin()
            val channel = MethodChannel(registrar.messenger(), "flutter.jeroengovers.nl/pusher")
                channel.setMethodCallHandler(instance)

            val connectionEventChannel = EventChannel(registrar.messenger(), "flutter.jeroengovers.nl/pusher/connection")
                connectionEventChannel.setStreamHandler(instance.connectionStreamHandler)

            val messageEventChannel = EventChannel(registrar.messenger(),"flutter.jeroengovers.nl/pusher/message")
                messageEventChannel.setStreamHandler(instance.messageStreamHandler)
        }
    }

    override fun onConnectionStateChange(change: ConnectionStateChange) {
        connectionStreamHandler.sendState(change.currentState)
    }

    override fun onError(message: String?, code: String?, e: Exception?) {
        e?.printStackTrace()
        val errMessage = message ?: e?.localizedMessage ?: "Unknown error"
        this.errorStreamHandler.send(code ?: "", errMessage)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val unit = when (call.method) {
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
            }
            "connect" -> {
                pusher?.connect(this, ConnectionState.ALL)
            }
            "subscribe" -> {
                val pusher = this.pusher ?: return
                val event = call.argument<String>("event")
                        ?: throw RuntimeException("Must provide event name")
                val channelName = call.argument<String>("channel")
                        ?: throw RuntimeException("Must provide channel")
                var channel = pusher.getChannel(channelName)
                if (channel == null) {
                    channel = pusher.subscribe(channelName)
                }
                channel.bind(event) { _, eventName, data ->
                    messageStreamHandler.send(channel.name, eventName, data)
                }
                result.success(null)
            }
            "subscribePrivate" -> {
                val pusher = this.pusher ?: return
                val event = call.argument<String>("event") ?: throw RuntimeException("Must provide event name")
                val channelName = call.argument<String>("channel") ?: throw RuntimeException("Must provide channel")

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
                            messageStreamHandler.send(channel.name, eventName, data)
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
                        messageStreamHandler.send(channel.name, eventName, data)
                    }
                })
                result.success(null)
            }
            "trigger" -> {
                val pusher = this.pusher ?: return

                val channelName = call.argument<String>("channel") ?: throw RuntimeException("Must provide channel")
                val event = call.argument<String>("event") ?: throw RuntimeException("Must provide event name")
                val data = call.argument<String>("data") ?: throw RuntimeException("Must provide data")

                val channel = pusher.getPrivateChannel(channelName)
                channel.trigger(event, data)
            }
            else -> result.notImplemented()
        }
    }
}

class ConnectionStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun sendState(state: ConnectionState) {
        eventSink?.success(state.toString().toLowerCase())
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }
}

class MessageStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun send(channel: String, event: String, data: Any) {
        val json = JSONObject(data as String)
        val map = jsonToMap(json)
        eventSink?.success(mapOf("channel" to channel,
                "event" to event,
                "body" to map))
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }
}
class ErrorStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun send(code : String, message : String) {
        val errCode = try { code.toInt() } catch (e : NumberFormatException) { 0 }
        eventSink?.success(mapOf("code" to errCode, "message" to message))
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