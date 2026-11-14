using Microsoft.Extensions.Logging;
using Bozras.Application.Common;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Enums;

namespace Bozras.Infrastructure.Notifications;

public class ShopRequestNotifier : IShopRequestNotifier
{
    private readonly IUserRepository _users;
    private readonly IPushQueue _queue;
    private readonly ILogger<ShopRequestNotifier> _logger;

    public ShopRequestNotifier(
        IUserRepository users,
        IPushQueue queue,
        ILogger<ShopRequestNotifier> logger)
    {
        _users = users;
        _queue = queue;
        _logger = logger;
    }

    public async Task NotifyAsync(Guid supplierId, string shopName, CancellationToken ct = default)
    {
        try
        {
            var admins = await _users.GetFcmTargetsByRoleAsync(UserRole.Admin, supplierId, ct);

            var data = new Dictionary<string, string>
            {
                ["type"] = "shop_request",
                ["supplierId"] = supplierId.ToString()
            };

            foreach (var admin in admins)
                _queue.Enqueue(new PushMessage(
                    admin.Token,
                    "Новая заявка магазина",
                    $"{shopName} хочет подключиться к вам",
                    data));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Не удалось подготовить уведомление о заявке для поставщика {SupplierId}.", supplierId);
        }
    }
}