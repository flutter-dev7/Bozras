using Microsoft.EntityFrameworkCore;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Common;
using Bozras.Domain.Entities;

namespace Bozras.Infrastructure.Persistence.Data;

public class AppDbContext : DbContext
{
    private readonly ITenantContext _tenant;

    public AppDbContext(DbContextOptions<AppDbContext> options, ITenantContext tenant) : base(options)
    {
        _tenant = tenant;
    }

    private Guid? CurrentSupplierId => _tenant.SupplierId;

    public DbSet<User> Users => Set<User>();
    public DbSet<Shop> Shops => Set<Shop>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<OrderStatusHistory> OrderStatusHistories => Set<OrderStatusHistory>();
    public DbSet<Visit> Visits => Set<Visit>();
    public DbSet<Setting> Settings => Set<Setting>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<StockMovement> StockMovements => Set<StockMovement>();

    public DbSet<Supplier> Suppliers => Set<Supplier>();
    public DbSet<Plan> Plans => Set<Plan>();
    public DbSet<Location> Locations => Set<Location>();
    public DbSet<ServiceArea> ServiceAreas => Set<ServiceArea>();
    public DbSet<ShopProfile> ShopProfiles => Set<ShopProfile>();
    public DbSet<SubscriptionPayment> SubscriptionPayments => Set<SubscriptionPayment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        ApplyTenantFilter<Product>(modelBuilder);
        ApplyTenantFilter<Category>(modelBuilder);
        ApplyTenantFilter<StockMovement>(modelBuilder);
        ApplyTenantFilter<Shop>(modelBuilder);
        ApplyTenantFilter<Order>(modelBuilder);
        ApplyTenantFilter<OrderItem>(modelBuilder);
        ApplyTenantFilter<OrderStatusHistory>(modelBuilder);
        ApplyTenantFilter<Payment>(modelBuilder);
        ApplyTenantFilter<Setting>(modelBuilder);
        ApplyTenantFilter<Visit>(modelBuilder);

        var tenantTypes = modelBuilder.Model
            .GetEntityTypes()
            .Where(t => typeof(ITenantEntity).IsAssignableFrom(t.ClrType))
            .Select(t => t.ClrType)
            .ToList();

        foreach (var type in tenantTypes)
        {
            var builder = modelBuilder.Entity(type);

            builder.HasOne(typeof(Supplier))
                .WithMany()
                .HasForeignKey(nameof(ITenantEntity.SupplierId))
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(nameof(ITenantEntity.SupplierId));
        }
    }

    public override int SaveChanges(bool acceptAllChangesOnSuccess)
    {
        AssignSupplier();

        return base.SaveChanges(acceptAllChangesOnSuccess);
    }

    public override Task<int> SaveChangesAsync(
        bool acceptAllChangesOnSuccess, CancellationToken cancellationToken = default)
    {
        AssignSupplier();

        return base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
    }

    private void ApplyTenantFilter<T>(ModelBuilder modelBuilder) where T : class, ITenantEntity
    {
        modelBuilder.Entity<T>().HasQueryFilter(e => e.SupplierId == CurrentSupplierId);
    }

    private void AssignSupplier()
    {
        foreach (var entry in ChangeTracker.Entries<ITenantEntity>())
        {
            if (entry.State != EntityState.Added || entry.Entity.SupplierId != Guid.Empty)
                continue;

            entry.Entity.SupplierId = _tenant.SupplierId
                ?? throw new InvalidOperationException("Не определён поставщик для сохранения данных.");
        }
    }
}