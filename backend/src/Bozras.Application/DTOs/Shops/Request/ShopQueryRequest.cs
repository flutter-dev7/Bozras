using Bozras.Application.Common;

namespace Bozras.Application.DTOs.Shops.Request;

public class ShopQueryRequest : PaginationRequest
{
    public string? Search { get; set; }
    public bool? IsActive { get; set; }
}