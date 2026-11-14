namespace Bozras.Application.Interfaces.Services;

public interface IShopRequestNotifier
{
    Task NotifyAsync(Guid supplierId, string shopName, CancellationToken ct = default);
}