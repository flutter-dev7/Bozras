namespace Bozras.Application.DTOs.Suppliers.Request;

public class SupplierQueryRequest
{
    public string? Search { get; set; }
    public bool? IsActive { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}