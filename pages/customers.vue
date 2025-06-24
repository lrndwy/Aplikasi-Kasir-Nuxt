<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-2 sm:p-4">
    <h1 class="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-gray-900 dark:text-white">
      Manajemen Pelanggan
    </h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div v-else-if="!hasAdminOrManagerRole" class="text-center text-red-500 dark:text-red-400">
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else>
      <div class="mb-6 flex justify-end">
        <Dialog :open="isCustomerFormOpen" @update:open="isCustomerFormOpen = $event">
          <DialogTrigger as-child>
            <Button @click="addNewCustomer">Tambah Pelanggan Baru</Button>
          </DialogTrigger>
          <DialogContent class="sm:max-w-[600px] p-6 max-h-[80vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>{{
                isEditing ? "Edit Pelanggan" : "Tambah Pelanggan Baru"
              }}</DialogTitle>
              <DialogDescription>
                {{
                  isEditing
                    ? "Perbarui detail pelanggan."
                    : "Tambahkan pelanggan baru ke daftar."
                }}
              </DialogDescription>
            </DialogHeader>
            <form @submit.prevent="saveCustomer" class="space-y-4 py-4">
              <div>
                <Label for="customerName" class="mb-2">Nama Pelanggan</Label>
                <Input
                  id="customerName"
                  v-model="customerForm.name"
                  type="text"
                  placeholder="Nama Pelanggan"
                  required
                />
              </div>
              <div>
                <Label for="customerEmail" class="mb-2">Email</Label>
                <Input
                  id="customerEmail"
                  v-model="customerForm.email"
                  type="email"
                  placeholder="email@example.com"
                />
              </div>
              <div>
                <Label for="customerPhone" class="mb-2">Telepon</Label>
                <Input
                  id="customerPhone"
                  v-model="customerForm.phone"
                  type="text"
                  placeholder="Nomor Telepon"
                />
              </div>
              <div>
                <Label for="customerAddress" class="mb-2">Alamat</Label>
                <Textarea
                  id="customerAddress"
                  v-model="customerForm.address"
                  placeholder="Alamat Lengkap"
                />
              </div>
              <DialogFooter class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2 pt-4">
                <DialogClose as-child>
                  <Button type="button" variant="outline" @click="cancelEdit"
                    class="w-full sm:w-auto mb-2 sm:mb-0"
                    >Batal</Button
                  >
                </DialogClose>
                <Button
                  v-if="isEditing"
                  type="button"
                  variant="destructive"
                  @click="confirmDeleteCustomer(customerForm.id)"
                  :disabled="loading"
                  class="w-full sm:w-auto mb-2 sm:mb-0"
                >
                  Hapus Pelanggan
                </Button>
                <Button type="submit" :disabled="loading" class="w-full sm:w-auto">
                  <span v-if="loading">Menyimpan...</span>
                  <span v-else>{{
                    isEditing ? "Perbarui Pelanggan" : "Tambah Pelanggan"
                  }}</span>
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <!-- Daftar Pelanggan -->
      <Card>
        <CardHeader>
          <CardTitle>Daftar Pelanggan</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="overflow-x-auto">
            <Table class="min-w-full">
              <TableHeader>
                <TableRow>
                  <TableHead class="min-w-[150px]">Nama</TableHead>
                  <TableHead class="min-w-[120px] hidden md:table-cell">Email</TableHead>
                  <TableHead class="min-w-[100px] hidden md:table-cell">Telepon</TableHead>
                  <TableHead class="min-w-[150px] hidden md:table-cell">Alamat</TableHead>
                  <TableHead class="min-w-[150px] hidden md:table-cell">Dibuat Pada</TableHead>
                  <TableHead class="min-w-[150px] hidden md:table-cell">Diperbarui Pada</TableHead>
                  <TableHead class="min-w-[150px]">Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableRow v-for="customer in customers" :key="customer.id" @click="showCustomerDetail(customer)" class="cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700">
                  <TableCell>{{ customer.name }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ customer.email || "-" }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ customer.phone || "-" }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ customer.address || "-" }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ formatDate(customer.created_at) }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ formatDate(customer.updated_at) }}</TableCell>
                  <TableCell @click.stop>
                    <DropdownMenu>
                      <DropdownMenuTrigger as-child>
                        <Button variant="ghost" class="h-8 w-8 p-0">
                          <span class="sr-only">Open menu</span>
                          <MoreHorizontal class="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuLabel>Aksi</DropdownMenuLabel>
                        <DropdownMenuItem @click="showCustomerDetail(customer)">
                          <Info class="mr-2 h-4 w-4" />Detail
                        </DropdownMenuItem>
                        <DropdownMenuItem @click="editCustomer(customer)">
                          <Edit class="mr-2 h-4 w-4" />Edit
                        </DropdownMenuItem>
                        <DropdownMenuItem @click="confirmDeleteCustomer(customer.id)">
                          <Trash2 class="mr-2 h-4 w-4" />Hapus
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </div>
          <div
            v-if="customers.length === 0 && !loading"
            class="text-center text-gray-500 dark:text-gray-400 mt-4"
          >
            Tidak ada pelanggan ditemukan.
          </div>
        </CardContent>
      </Card>

      <!-- Delete Confirmation Dialog -->
      <Dialog :open="isConfirmDeleteOpen" @update:open="isConfirmDeleteOpen = $event">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Konfirmasi Hapus Pelanggan</DialogTitle>
            <DialogDescription>
              Apakah Anda yakin ingin menghapus pelanggan ini? Tindakan ini tidak dapat
              dibatalkan.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" @click="isConfirmDeleteOpen = false">Batal</Button>
            <Button
              variant="destructive"
              @click="deleteCustomerConfirmed"
              :disabled="loading"
            >
              <span v-if="loading">Menghapus...</span>
              <span v-else>Hapus</span>
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <!-- Customer Detail Dialog -->
      <Dialog :open="isCustomerDetailOpen" @update:open="isCustomerDetailOpen = $event">
        <DialogContent class="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Detail Pelanggan</DialogTitle>
            <DialogDescription>Informasi lengkap mengenai pelanggan ini.</DialogDescription>
          </DialogHeader>
          <div v-if="selectedCustomer" class="grid gap-4 py-4">
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailName" class="text-right">Nama</Label>
              <Input id="detailName" :model-value="selectedCustomer.name" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailEmail" class="text-right">Email</Label>
              <Input id="detailEmail" :model-value="selectedCustomer.email || 'Tidak ada email'" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailPhone" class="text-right">Telepon</Label>
              <Input id="detailPhone" :model-value="selectedCustomer.phone || 'Tidak ada telepon'" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailAddress" class="text-right">Alamat</Label>
              <Textarea id="detailAddress" :model-value="selectedCustomer.address || 'Tidak ada alamat'" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailCreatedAt" class="text-right">Dibuat Pada</Label>
              <Input id="detailCreatedAt" :model-value="formatDate(selectedCustomer.created_at)" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailUpdatedAt" class="text-right">Diperbarui Pada</Label>
              <Input id="detailUpdatedAt" :model-value="formatDate(selectedCustomer.updated_at)" readonly class="col-span-3" />
            </div>
          </div>
          <DialogFooter>
            <DialogClose as-child>
              <Button type="button" variant="outline">Tutup</Button>
            </DialogClose>
            <Button @click="editCustomer(selectedCustomer!)">
              <Edit class="mr-2 h-4 w-4" />Edit Pelanggan
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
    <Toaster />
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Customers - Aplikasi Kasir'
})
import { ref, onMounted, watch } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { toast } from 'vue-sonner';
import { Toaster } from '@/components/ui/sonner';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import 'vue-sonner/style.css'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogClose,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreHorizontal, Edit, Trash2, Info } from "lucide-vue-next";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

interface Customer {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  address: string | null;
  created_at: string;
  updated_at: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const customers = ref<Customer[]>([]);
const customerForm = ref({
  id: "",
  name: "",
  email: "",
  phone: "",
  address: "",
});
const pageLoading = ref(true); // New ref for overall page loading
const isEditing = ref(false);
const loading = ref(false);
const hasAdminOrManagerRole = ref(false);
const isCustomerFormOpen = ref(false); // Controls the add/edit customer dialog
const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog
const customerToDeleteId = ref<string | null>(null); // Stores the ID of the customer to be deleted
const isCustomerDetailOpen = ref(false); // Controls the customer detail dialog
const selectedCustomer = ref<Customer | null>(null); // Stores the selected customer for detail view

const fetchCustomers = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from("customers")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;
    customers.value = data as Customer[];
  } catch (error: any) {
    toast.error("Gagal memuat pelanggan!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const checkUserRole = async () => {
  if (!user.value) {
    hasAdminOrManagerRole.value = false;
    return;
  }
  const { data, error } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.value.id)
    .single();

  if (error) {
    toast.error("Gagal memeriksa peran pengguna!", {
      description: error.message,
    });
    hasAdminOrManagerRole.value = false;
    return;
  }
  if (!data) {
    toast.error("Data profil pengguna tidak ditemukan.");
    hasAdminOrManagerRole.value = false;
    return;
  }
  hasAdminOrManagerRole.value = data?.role === "admin" || data?.role === "manager";
  if (!hasAdminOrManagerRole.value) {
    toast.warning("Anda tidak memiliki izin untuk mengakses halaman ini.", {
      description: "Silakan hubungi administrator untuk mendapatkan akses.",
    });
  }
};

const saveCustomer = async () => {
  loading.value = true;

  try {
    const customerData = {
      name: customerForm.value.name,
      email: customerForm.value.email || null,
      phone: customerForm.value.phone || null,
      address: customerForm.value.address || null,
    };

    if (isEditing.value) {
      const { error } = await supabase
        .from("customers")
        .update({ ...customerData, updated_at: new Date().toISOString() })
        .eq("id", customerForm.value.id);
      if (error) throw error;
      toast.success("Pelanggan berhasil diperbarui!", {
        description: `Pelanggan ${customerForm.value.name} telah berhasil diperbarui.`,
      });
    } else {
      const { error } = await supabase.from("customers").insert(customerData);
      if (error) throw error;
      toast.success("Pelanggan berhasil ditambahkan!", {
        description: `Pelanggan ${customerForm.value.name} telah berhasil ditambahkan.`,
      });
    }
    resetForm();
    await fetchCustomers();
    isCustomerFormOpen.value = false; // Close the dialog on success
  } catch (error: any) {
    toast.error("Gagal menyimpan pelanggan!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const addNewCustomer = () => {
  resetForm();
  isCustomerFormOpen.value = true;
};

const editCustomer = (customer: Customer) => {
  isEditing.value = true;
  customerForm.value = { ...customer };
  isCustomerFormOpen.value = true; // Open the dialog for editing
  isCustomerDetailOpen.value = false; // Close detail dialog if open
};

const showCustomerDetail = (customer: Customer) => {
  selectedCustomer.value = customer;
  isCustomerDetailOpen.value = true;
};

const cancelEdit = () => {
  resetForm();
  isCustomerFormOpen.value = false; // Close the dialog on cancel
};

const confirmDeleteCustomer = (id: string) => {
  customerToDeleteId.value = id;
  isCustomerFormOpen.value = false; // Close the customer form dialog
  isConfirmDeleteOpen.value = true;
};

const deleteCustomerConfirmed = async () => {
  if (!customerToDeleteId.value) return;

  loading.value = true;
  try {
    const { error } = await supabase
      .from("customers")
      .delete()
      .eq("id", customerToDeleteId.value);
    if (error) throw error;
    loading.value = false; // Set loading to false before closing dialog
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    customerToDeleteId.value = null; // Clear the ID
    toast.success("Pelanggan berhasil dihapus!", {
      description: "Pelanggan telah berhasil dihapus dari daftar.",
    });
    await fetchCustomers();
  } catch (error: any) {
    toast.error("Gagal menghapus pelanggan!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
  isEditing.value = false;
  customerForm.value = {
    id: "",
    name: "",
    email: "",
    phone: "",
    address: "",
  };
};

onMounted(async () => {
  pageLoading.value = true; // Start loading state
  try {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCustomers();
    }
  } catch (error: any) {
    toast.error("Terjadi kesalahan saat memuat data awal!", {
      description: error.message,
    });
  } finally {
    pageLoading.value = false; // End loading state
  }
});

watch(user, async (newUser) => {
  if (newUser) {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCustomers();
    }
  } else {
    hasAdminOrManagerRole.value = false;
    customers.value = [];
  }
});

const formatDate = (dateString: string) => {
  const options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  };
  return new Date(dateString).toLocaleDateString("id-ID", options);
};
</script>

b<style scoped>
.spinner {
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-left-color: #3b82f6; /* Blue-500 */
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
