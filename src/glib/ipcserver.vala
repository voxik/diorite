/*
 * Copyright 2014-2016 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

namespace Diorite.Ipc
{

public class Server: GLib.Object
{
	private static bool log_comunication;
	
	static construct
	{
		log_comunication = Environment.get_variable("DIORITE_LOG_IPC_SERVER") == "yes";
	}
	
	public bool listening
	{
		get {return service != null && service.is_active();}
	}
	
	public uint timeout {get; set;}
	public string name {get; private set;}
	private SocketService? service=null;
	
	public Server(string name, uint timeout=5000)
	{
		this.name = name;
		this.timeout = timeout;
	}
	
	public void start_service() throws IOError
	{
		service = create_socket_service(create_path(name));
		service.incoming.connect(on_incoming);
		service.start();
	}
	
	public void stop_service() throws IOError
	{
		if (service != null)
		{
			service.stop();
			service = null;
		}
	}
	
	public virtual signal void async_error(IOError e)
	{
		warning("Async IOError: %s", e.message);
	}
	
	private bool on_incoming(SocketConnection connection, GLib.Object? source_object)
	{
		process_connection.begin(connection, on_process_incoming_done);
		return true;
	}
	
	private void on_process_incoming_done(GLib.Object? o, AsyncResult result)
	{
		try
		{
			process_connection.end(result);
		}
		catch (IOError e)
		{
			if (log_comunication)
				debug("Connection processed with error: %s", e.message);
			async_error(e);
		}
	}
	
	private async void process_connection(SocketConnection connection) throws IOError
	{
		ByteArray request;
		var channel = new SocketChannel(create_path(name), connection);
		yield channel.read_bytes_async(out request, timeout);
		
		ByteArray response;
		if (!handle((owned) request, out response))
				response = new ByteArray();
		
		yield channel.write_bytes_async(response);
	}
	
	protected virtual bool handle(owned ByteArray request, out ByteArray response)
	{
		response = (owned) request;
		return true;
	}
}

} // namespace Diorote
