using Bozras.Domain.Enums;

namespace Bozras.Application.Common;

public record ShopSupplierLink(
    Guid SupplierId,
    string Name,
    string? Phone,
    string? Description,
    string? LogoUrl,
    bool RequiresApproval,
    ShopConnectionStatus Status,
    bool IsAvailable);