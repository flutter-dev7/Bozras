using Bozras.Application.Common;
using Bozras.Application.DTOs.Reports.Request;
using Bozras.Application.DTOs.Reports.Response;

namespace Bozras.Application.Interfaces.Services;

public interface IReportService
{
    Task<Result<ProductionReportResponse>> GetProductionAsync(
        ProductionReportRequest request, CancellationToken ct = default);

    Task<Result<SalesReportResponse>> GetSalesAsync(
        SalesReportRequest request, CancellationToken ct = default);
}