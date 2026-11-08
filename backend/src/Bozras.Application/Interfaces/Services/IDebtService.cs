using Bozras.Application.Common;
using Bozras.Application.DTOs.Debts.Request;
using Bozras.Application.DTOs.Debts.Response;

namespace Bozras.Application.Interfaces.Services;

public interface IDebtService
{
    Task<ShopBalance> GetBalanceAsync(Guid shopId, CancellationToken ct = default);

    Task<Result<ShopBalanceResponse>> GetShopBalanceAsync(Guid shopId, CurrentUser caller, CancellationToken ct = default);
    Task<Result<ShopBalanceResponse>> GetMyBalanceAsync(CurrentUser caller, CancellationToken ct = default);

    Task<Result<PagedResult<DebtListItemResponse>>> GetDebtsAsync(DebtQueryRequest request, CancellationToken ct = default);
}