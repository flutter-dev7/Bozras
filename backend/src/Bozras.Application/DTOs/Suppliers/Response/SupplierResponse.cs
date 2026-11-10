namespace Bozras.Application.DTOs.Suppliers.Response;

public class SupplierResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; }
    public bool RequiresApproval { get; set; }
    public Guid? PlanId { get; set; }
    public string? PlanName { get; set; }
    public string SubscriptionStatus { get; set; } = string.Empty;
    public DateTime? SubscriptionEndsAt { get; set; }
    public bool IsAccessAllowed { get; set; }
    public int ShopsCount { get; set; }
    public int StaffCount { get; set; }
    public string? AdminEmail { get; set; }
    public List<Guid> LocationIds { get; set; } = new();
    public DateTime CreatedAt { get; set; }
}