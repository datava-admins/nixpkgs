{
  imports = [ ./amazon-image.nix ];
  ec2.efi = true;
  amazonImage.bootSizeMB = 1500;
  amazonImage.sizeMB = "auto";
  amazonImage.fsType = "btrfs";
  amazonImage.btrfsSubvolumes = [ "/nix/store" "/home" "/var" ];
  ec2.fsType = "btrfs";
}
