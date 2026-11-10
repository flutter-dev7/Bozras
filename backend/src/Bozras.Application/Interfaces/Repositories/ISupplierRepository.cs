using Bozras.Application.Common;
using Bozras.Domain.Entities;

namespace Bozras.Application.Interfaces.Repositories;

public interface ISupplierRepository
{
    Task<(List<Supplier> Items, int TotalCount)> GetPagedAsync(
        string? search, bool? isActive, int page, int pageSize, CancellationToken ct = default);

    Task<Supplier?> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<bool> CodeExistsAsync(string code, CancellationToken ct = default);

    Task<Dictionary<Guid, SupplierStats>> GetStatsAsync(
        IReadOnlyCollection<Guid> ids, CancellationToken ct = default);

    Task<List<SubscriptionPayment>> GetPaymentsAsync(Guid supplierId, CancellationToken ct = default);

    Task AddAsync(Supplier supplier, CancellationToken ct = default);

    Task AddPaymentAsync(SubscriptionPayment payment, CancellationToken ct = default);
}