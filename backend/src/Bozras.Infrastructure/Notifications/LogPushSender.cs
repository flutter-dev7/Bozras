using Microsoft.Extensions.Logging;
using Bozras.Application.Common;
using Bozras.Application.Interfaces.Services;

namespace Bozras.Infrastructure.Notifications;

public sealed class LogPushSender : IPushSender
{
    private readonly ILogger<LogPushSender> _logger;

    public LogPushSender(ILogger<LogPushSender> logger)
    {
        _logger = logger;
    }

    public Task<PushResult> SendAsync(PushMessage message, CancellationToken ct = default)
    {
        _logger.LogInformation("Push (заглушка, Firebase не настроен): {Title} | {Body}", message.Title, message.Body);

        return Task.FromResult(PushResult.Sent);
    }
}