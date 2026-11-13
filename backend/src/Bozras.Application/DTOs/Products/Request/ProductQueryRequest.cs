using Bozras.Application.Common;

namespace Bozras.Application.DTOs.Products.Request;

public class ProductQueryRequest : PaginationRequest
{
    public string? Search { get; set; }
    public bool? IsActive { get; set; }
    public Guid? CategoryId { get; set; }
}