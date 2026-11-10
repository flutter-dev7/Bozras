using Bozras.Application.Common;
using Bozras.Application.DTOs.Plans.Request;
using Bozras.Application.DTOs.Plans.Response;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;

namespace Bozras.Application.Services;

public class PlanService : IPlanService
{
    private readonly IPlanRepository _plans;
    private readonly IUnitOfWork _unitOfWork;

    public PlanService(IPlanRepository plans, IUnitOfWork unitOfWork)
    {
        _plans = plans;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<List<PlanResponse>>> GetAllAsync(CancellationToken ct = default)
    {
        var plans = await _plans.GetAllAsync(ct);

        return Result<List<PlanResponse>>.Success(plans.Select(ToResponse).ToList());
    }

    public async Task<Result<PlanResponse>> CreateAsync(SavePlanRequest request, CancellationToken ct = default)
    {
        var name = request.Name.Trim();
        if (name.Length == 0)
            return Result<PlanResponse>.Failure("Укажите название.");

        if (await _plans.NameExistsAsync(name, null, ct))
            return Result<PlanResponse>.Failure("Тариф с таким названием уже существует.", ErrorType.Conflict);

        var plan = new Plan
        {
            Name = name,
            PricePerMonth = request.PricePerMonth,
            MaxShops = request.MaxShops,
            MaxStaff = request.MaxStaff,
            IsActive = request.IsActive
        };

        await _plans.AddAsync(plan, ct);
        await _unitOfWork.SaveChangesAsync(ct);

        return Result<PlanResponse>.Success(ToResponse(plan));
    }

    public async Task<Result<PlanResponse>> UpdateAsync(
        Guid id, SavePlanRequest request, CancellationToken ct = default)
    {
        var plan = await _plans.GetByIdAsync(id, ct);
        if (plan is null)
            return Result<PlanResponse>.Failure("Тариф не найден.", ErrorType.NotFound);

        var name = request.Name.Trim();
        if (name.Length == 0)
            return Result<PlanResponse>.Failure("Укажите название.");

        if (await _plans.NameExistsAsync(name, id, ct))
            return Result<PlanResponse>.Failure("Тариф с таким названием уже существует.", ErrorType.Conflict);

        plan.Name = name;
        plan.PricePerMonth = request.PricePerMonth;
        plan.MaxShops = request.MaxShops;
        plan.MaxStaff = request.MaxStaff;
        plan.IsActive = request.IsActive;

        await _unitOfWork.SaveChangesAsync(ct);

        return Result<PlanResponse>.Success(ToResponse(plan));
    }

    private static PlanResponse ToResponse(Plan plan) => new()
    {
        Id = plan.Id,
        Name = plan.Name,
        PricePerMonth = plan.PricePerMonth,
        MaxShops = plan.MaxShops,
        MaxStaff = plan.MaxStaff,
        IsActive = plan.IsActive
    };
}