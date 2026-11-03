namespace Non.Application.DTOs.Auth.Response;

public class SessionResponse
{
    public Guid Id { get; set; }
    public string DeviceName { get; set; } = string.Empty;
    public DateTime LastActiveAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public bool IsCurrent { get; set; }
}