using Bozras.Application.Common;

namespace Bozras.Application.Interfaces.Services;

public interface IPushSender
{
    Task<PushResult> SendAsync(PushMessage message, CancellationToken ct = default);
}