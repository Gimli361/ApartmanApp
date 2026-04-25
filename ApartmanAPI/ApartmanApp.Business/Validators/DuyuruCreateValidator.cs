using ApartmanApp.Business.DTOs.Bildirim;
using FluentValidation;

namespace ApartmanApp.Business.Validators;

public class DuyuruCreateValidator : AbstractValidator<DuyuruCreateDto>
{
    public DuyuruCreateValidator()
    {
        RuleFor(x => x.Baslik)
            .NotEmpty().WithMessage("Başlık boş olamaz.")
            .MaximumLength(100).WithMessage("Başlık en fazla 100 karakter olabilir.");

        RuleFor(x => x.Icerik)
            .NotEmpty().WithMessage("İçerik boş olamaz.")
            .MaximumLength(2000).WithMessage("İçerik en fazla 2000 karakter olabilir.");
    }
}

public class BlokBildirimValidator : AbstractValidator<BlokBildirimDto>
{
    public BlokBildirimValidator()
    {
        RuleFor(x => x.BlokNo)
            .NotEmpty().WithMessage("Blok No boş olamaz.")
            .MaximumLength(20);

        RuleFor(x => x.Baslik)
            .NotEmpty().WithMessage("Başlık boş olamaz.")
            .MaximumLength(100);

        RuleFor(x => x.Icerik)
            .NotEmpty().WithMessage("İçerik boş olamaz.")
            .MaximumLength(2000);
    }
}

public class DaireBildirimValidator : AbstractValidator<DaireBildirimDto>
{
    public DaireBildirimValidator()
    {
        RuleFor(x => x.DaireNo)
            .NotEmpty().WithMessage("Daire No boş olamaz.")
            .MaximumLength(20);

        RuleFor(x => x.Baslik)
            .NotEmpty().WithMessage("Başlık boş olamaz.")
            .MaximumLength(100);

        RuleFor(x => x.Icerik)
            .NotEmpty().WithMessage("İçerik boş olamaz.")
            .MaximumLength(2000);
    }
}
