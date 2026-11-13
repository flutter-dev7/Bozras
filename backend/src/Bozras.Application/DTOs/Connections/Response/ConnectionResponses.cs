using Bozras.Domain.Enums;

namespace Bozras.Application.DTOs.Connections.Response;

public class ShopProfileResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public Guid? LocationId { get; set; }
    public string? LocationName { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

public class SupplierCardResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Description { get; set; }
    public string? LogoUrl { get; set; }
    public bool RequiresApproval { get; set; }
    public ShopConnectionStatus? ConnectionStatus { get; set; }
}

public class MySupplierResponse
{
    public Guid SupplierId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Description { get; set; }
    public string? LogoUrl { get; set; }
    public ShopConnectionStatus Status { get; set; }
    public bool IsAvailable { get; set; }
}

public class SupplierProfileResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Description { get; set; }
    public string? LogoUrl { get; set; }
    public bool RequiresApproval { get; set; }
    public string? PlanName { get; set; }
    public SubscriptionStatus SubscriptionStatus { get; set; }
    public DateTime? SubscriptionEndsAt { get; set; }
}

public class ShopRequestResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? OwnerName { get; set; }
    public string? OwnerPhone { get; set; }
}