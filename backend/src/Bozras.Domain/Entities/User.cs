using Bozras.Domain.Common;
using Bozras.Domain.Enums;

namespace Bozras.Domain.Entities;

public class User : BaseEntity
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? PasswordHash { get; set; }
    public bool EmailConfirmed { get; set; }
    public UserRole Role { get; set; }
    public bool IsActive { get; set; } = true;
    public string? FcmToken { get; set; }
    public Guid? SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public string FullName => $"{FirstName} {LastName}".Trim();
}