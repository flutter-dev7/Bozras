using Bozras.Application.Common;
using Bozras.Domain.Entities;

namespace Bozras.Application.Interfaces.Services;

public interface IOrderNotifier
{
    Task NotifyAsync(OrderEvent kind, Order order, CurrentUser actor, CancellationToken ct = default);
}