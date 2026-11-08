using System.Threading.Channels;
using Bozras.Application.Common;
using Bozras.Application.Interfaces.Services;

namespace Bozras.Infrastructure.Notifications;

public sealed class PushQueue : IPushQueue
{
    private readonly Channel<PushMessage> _channel = Channel.CreateBounded<PushMessage>(
        new BoundedChannelOptions(1000)
        {
            FullMode = BoundedChannelFullMode.DropOldest,
            SingleReader = true
        });

    public ChannelReader<PushMessage> Reader => _channel.Reader;

    public void Enqueue(PushMessage message) => _channel.Writer.TryWrite(message);
}