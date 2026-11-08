using Bozras.Application.Common;
using Bozras.Application.DTOs.Orders.Request;
using Bozras.Application.DTOs.Orders.Response;

namespace Bozras.Application.Interfaces.Services;

public interface IOrderService
{
    Task<Result<PagedResult<OrderResponse>>> GetPagedAsync(
        OrderQueryRequest request, CurrentUser caller, CancellationToken ct = default);

    Task<Result<OrderDetailsResponse>> GetByIdAsync(Guid id, CurrentUser caller, CancellationToken ct = default);

    Task<Result<OrderDetailsResponse>> CreateAsync(
        CreateOrderRequest request, CurrentUser caller, CancellationToken ct = default);

    Task<Result<OrderDetailsResponse>> ChangeStatusAsync(
        Guid id, ChangeOrderStatusRequest request, CurrentUser caller, CancellationToken ct = default);

    Task<Result<OrderDetailsResponse>> CancelAsync(Guid id, CurrentUser caller, CancellationToken ct = default);

    Task<Result<OrderDetailsResponse>> AssignCourierAsync(
        Guid id, AssignCourierRequest request, CurrentUser caller, CancellationToken ct = default);
    
    Task<Result<OrderDetailsResponse>> UpdateAsync(
        Guid id, UpdateOrderRequest request, CurrentUser caller, CancellationToken ct = default);
}