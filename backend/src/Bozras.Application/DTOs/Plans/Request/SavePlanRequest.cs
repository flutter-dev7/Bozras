using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Plans.Request;

public class SavePlanRequest
{
    [Required, StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Range(0, 100000000)]
    public decimal PricePerMonth { get; set; }

    [Range(1, 1000000)]
    public int? MaxShops { get; set; }

    [Range(1, 1000000)]
    public int? MaxStaff { get; set; }

    public bool IsActive { get; set; } = true;
}