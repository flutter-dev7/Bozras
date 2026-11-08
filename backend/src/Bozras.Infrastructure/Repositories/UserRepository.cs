using Microsoft.EntityFrameworkCore;
using Bozras.Application.Common;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;
using Bozras.Infrastructure.Persistence.Data;

namespace Bozras.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly AppDbContext _context;
    private readonly ITenantContext _tenant;

    public UserRepository(AppDbContext context, ITenantContext tenant)
    {
        _context = context;
        _tenant = tenant;
    }

    private IQueryable<User> ScopedUsers()
    {
        var supplierId = _tenant.SupplierId;

        if (supplierId is null)
            return _context.Users.Where(_ => false);

        var id = supplierId.Value;

        return _context.Users.Where(u =>
            u.Role != UserRole.SuperAdmin &&
            (u.SupplierId == id || _context.Shops.Any(s => s.UserId == u.Id)));
    }

    public Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == id, ct);

    public Task<User?> GetTrackedByIdAsync(Guid id, CancellationToken ct = default) =>
        _context.Users.FirstOrDefaultAsync(u => u.Id == id, ct);

    public Task<User?> GetScopedByIdAsync(Guid id, CancellationToken ct = default) =>
        ScopedUsers().AsNoTracking().FirstOrDefaultAsync(u => u.Id == id, ct);

    public Task<User?> GetScopedTrackedByIdAsync(Guid id, CancellationToken ct = default) =>
        ScopedUsers().FirstOrDefaultAsync(u => u.Id == id, ct);

    public Task<User?> GetByPhoneAsync(string phone, CancellationToken ct = default) =>
        _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Phone == phone, ct);

    public async Task<(List<User> Items, int TotalCount)> GetPagedAsync(
        string? search, UserRole? role, bool? isActive, int page, int pageSize, CancellationToken ct = default)
    {
        var query = ScopedUsers().AsNoTracking();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var pattern = $"%{search.Trim()}%";
            query = query.Where(u =>
                EF.Functions.ILike(u.FirstName + " " + u.LastName, pattern) ||
                EF.Functions.ILike(u.Phone, pattern));
        }

        if (role.HasValue)
            query = query.Where(u => u.Role == role.Value);

        if (isActive.HasValue)
            query = query.Where(u => u.IsActive == isActive.Value);

        var totalCount = await query.CountAsync(ct);

        var items = await query
            .OrderBy(u => u.FirstName)
            .ThenBy(u => u.LastName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return (items, totalCount);
    }

    public Task<List<User>> GetTrackedByFcmTokenAsync(string token, CancellationToken ct = default) =>
        _context.Users.Where(u => u.FcmToken == token).ToListAsync(ct);

    public Task<List<FcmTarget>> GetFcmTargetsByRoleAsync(
        UserRole role, Guid supplierId, CancellationToken ct = default) =>
        _context.Users
            .AsNoTracking()
            .Where(u => u.Role == role
                        && u.SupplierId == supplierId
                        && u.IsActive
                        && u.FcmToken != null
                        && u.FcmToken != "")
            .Select(u => new FcmTarget(u.Id, u.FcmToken!))
            .ToListAsync(ct);

    public Task<User?> GetByEmailAsync(string email, CancellationToken ct = default) =>
        _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Email == email, ct);

    public Task<User?> GetTrackedByEmailAsync(string email, CancellationToken ct = default) =>
        _context.Users.FirstOrDefaultAsync(u => u.Email == email, ct);

    public async Task AddAsync(User user, CancellationToken ct = default)
    {
        await _context.Users.AddAsync(user, ct);
    }
}