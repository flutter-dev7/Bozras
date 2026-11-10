namespace Bozras.Application.DTOs.Plans.Response;

public class PlanResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal PricePerMonth { get; set; }
    public int? MaxShops { get; set; }
    public int? MaxStaff { get; set; }
    public bool IsActive { get; set; }
}