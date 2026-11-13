using Bozras.Domain.Common;

namespace Bozras.Domain.Entities;

public class RefreshToken : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public string TokenHash { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }

    public DateTime? RevokedAt { get; set; }
    public Guid? ReplacedByTokenId { get; set; }
    
    public Guid SessionId { get; set; }
    public string? DeviceName { get; set; }

    public bool IsActive(DateTime now) => RevokedAt is null && ExpiresAt > now;
}