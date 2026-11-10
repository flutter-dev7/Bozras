using Bozras.Application.Common;
using Bozras.Application.DTOs.Suppliers.Request;
using Bozras.Application.DTOs.Suppliers.Response;

namespace Bozras.Application.Interfaces.Services;

public interface ISupplierService
{
    Task<Result<PagedResult<SupplierResponse>>> GetPagedAsync(
        SupplierQueryRequest request, CancellationToken ct = default);

    Task<Result<SupplierResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<Result<SupplierResponse>> CreateAsync(CreateSupplierRequest request, CancellationToken ct = default);

    Task<Result<SupplierResponse>> UpdateAsync(
        Guid id, UpdateSupplierRequest request, CancellationToken ct = default);

    Task<Result<SupplierResponse>> RegenerateCodeAsync(Guid id, CancellationToken ct = default);

    Task<Result<List<SubscriptionPaymentResponse>>> GetPaymentsAsync(Guid id, CancellationToken ct = default);

    Task<Result<SubscriptionPaymentResponse>> RecordPaymentAsync(
        Guid id, RecordSubscriptionPaymentRequest request, Guid userId, CancellationToken ct = default);
}